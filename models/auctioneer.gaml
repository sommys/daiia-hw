/**
* Name: auctioneer
* Auctioneer species for the homework 
* Author: Andreas Naoum, Soma Seres
*/

model auctioneer

import "global_species.gaml"

global{	
	/**
	 * Time when the auctioneer should pop up
	 */
	int auctioneerTime <- rnd(0, 50);
	
	/**
	 * Flag for indicating if auctioneers are present
	 */
	bool auctioneersCreated <- false;
	
	/**
	 * Flag for turning the multiple items for auctions on and off (Homework 2, Challenge 1)
	 */
	bool extra_multi_items <- false;
	
	/**
	 * Possible items for sale at the festival on auctions
	 */
 	list<string> possibleItems <- ["CD", "Bag", "T-shirt", "Hoodie"];
 	
	/**
	 * Number of auctioneers at the festival
	 */
	int num_auctioneer <- extra_multi_items ? length(possibleItems) : 1;
	
	reflex createAuctioneers when:(!auctioneersCreated and time >= auctioneerTime){
		auctioneersCreated <- true;
		if(extra_multi_items){
			loop item over: possibleItems{
				create Auctioneer{
					sellingItem <- item;
					do announceAuction;
				}
			}
		} else {
			create Auctioneer{
				do announceAuction;
			}
		}
	}
}
/**
 * The species representing the auctioneers at the festival.
 * It has the fipa skill, so it can send Guests infos about the auctions and communicate during the auction.
 */
species Auctioneer skills:[fipa]{
	/**
	 * Flag for testing different scenarios for different types of auctions (Homework 2, Challenge 2)
	 * 0 <- Random (1000-1500)
	 * 1 <- 1000
	 * 2 <- 5000
	 * 3 <- 100000
	 */
	int test_scenario <- 0;
	
	/**
	 * Auction Types
	 * 0 <- Dutch
	 * 1 <- English
	 * 2 <- Sealed-Bid 
	 * 3 <- Vickrey 
	 */
	int auctionType <- 0;
	
	/**
	 * Flag for keeping track of the state of the auction (running/not)
	 */
	bool auctionRunning <- false;
	/**
	 * The real value of the item for sale
	 */
	int realValue <- rnd(1000, 1500);
	/**
	 * The current price for the item in the auction
	 */
	int currentPrice <- round(realValue * rnd(1.5, 2.0));
	
	/**
	 * The sold item (only relevant if multiple items are available) 
	 */
	string sellingItem <- nil;
	
	/**
	 * List of interested guests, so only they receive info about the auction
	 */
	list<Guest> interestedGuests <- [];
	/**
	 * Counter for processed responses for the announcement
	 */
	int processed <- 0;

	/**
	 * The minimum acceptible price for the auctioneer (for Dutch Auction)
	 */
	int dutchMinPrice <- round(realValue * rnd(0.8, 0.9));
	/**
	 * The step by which the price is decreased in each round (for Dutch Auction)
	 */
	int dutchPriceStep <- round(realValue * 0.05);
	
	/**
	 * The second highest bid (for Vickrey Auction)
	 */
	int vickreySecondHighest <- 0;
	
	/**
	 * The current winner of the auction
	 */
	Guest highestCurrentBidder <- nil;
		
	/**
	 * Helper action for getting the name of the type of the auction based on its ID
	 */
	string getAuctionText(int type){
		if (auctionType = 0) {
			return "Dutch";
		}
		else if (auctionType = 1) {
			return "English";
		} 
		else if (auctionType = 2) {
			return "Sealed-Bid";
		} else if (auctionType = 3) {
			return "Vickrey";
		}
		return "Not Implemented";
	}
	
	/**
	 * Helper action for setting testing values for the auction
	 */
	action setScenario(int scenario) {
		if (scenario = 1){
			realValue <- 1000;
			if (auctionType = 0) {
				currentPrice <- 1700;
				dutchMinPrice <- 800;
				dutchPriceStep <- round(realValue * 0.05);
			}
			else {
				currentPrice <- 1000;
			}
			return;
		} 
		if (scenario = 2){
			realValue <- 5000;
			if (auctionType = 0) {
				currentPrice <- 8000;
				dutchMinPrice <- 4000;
				dutchPriceStep <- round(realValue * 0.05);
			}
			else {
				currentPrice <- 5000;
			}
			return;
		}
		if (scenario = 3){
			realValue <- 100000;
			if (auctionType = 0) {
				currentPrice <- 120000;
				dutchMinPrice <- 80000;
				dutchPriceStep <- round(realValue * 0.05);
			}
			else {
				currentPrice <- 100000;
			}
		}
	}
	
	/**
	 * Action for announcing the auction.
	 * Sends out the Start message with all relevant information about it.
	 */
	action announceAuction {
		//Set the testing scenario, if it is specified
		if (test_scenario > 0) {
			do setScenario scenario: test_scenario;
		}
		//Log the details and send it as a FIPA message
		write "["+name+"]: Hey dear guests! " + getAuctionText(auctionType) +  " Auction starting " + (extra_multi_items ? ("for " + sellingItem) : "") + " soon at (" + int(location.x) + ";" + int(location.y) + ")!";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ["Start", getAuctionText(auctionType), location, currentPrice, sellingItem]);
		//If there are no multiple items for sale, all guests are interested in the auction
		if(!extra_multi_items){
			interestedGuests <- list(Guest);
		}
	}
	
	/**
	 * Action for stopping the auction.
	 * Send out the stop message and remove the auctioneer.
	 */
	action stopAuction {
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop", sellingItem]);
		auctionRunning <- false;
		if(test_scenario > 0){
			int gain <- currentPrice - realValue;
			if(auctionType=0){
				 gain <- currentPrice - dutchMinPrice;
			} else if(auctionType=3){
				gain <- vickreySecondHighest - realValue;
			}
			write "[" + name + "]: Gained value for me: " + gain;
		}
		write "[" + name + "]: Auction is over, goodbye!";
		do die;
	}
	
	/**
	 * Handle responses for the auction proposal (in case of multiple available items)
	 */
	reflex auctionInfo when: extra_multi_items and !empty(cfps){
		message msg <- cfps at 0;
		if(msg.contents[0] = "Interested"){
			add item: msg.sender to: interestedGuests;
		}
		processed <- processed + 1;
	}
	
	/**
	 * Cancel the auction if there were no interested guests (in case of multiple available items)
	 */
	reflex cancelAuction when: !auctionRunning and extra_multi_items and processed = num_guest and length(interestedGuests) = 0 {
		do stopAuction;
	}
	
	/**
	 * Start the auction if all participants are ready and at the auctioneer
	 */
	reflex canStartAuction when: !auctionRunning and (!extra_multi_items or processed = num_guest) and length(interestedGuests) > 0 and interestedGuests max_of (location distance_to(each.location)) < distance_threshold{
		auctionRunning <- true;
		write "[" + name + "]: Starting with proposal " + currentPrice;
		do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: [currentPrice]);
	}
	
	/**
	 * Handle the responses for the Dutch auction
	 */
	reflex handleDutch when: auctionRunning and auctionType=0 and (!empty(reject_proposals) or !empty(accept_proposals)){
		if(!empty(accept_proposals)){ //If someone accepted the last proposal
			//In the unlikely case multiple guests accepter the last proposal, randomly pick the winner
			message winner <- shuffle(accept_proposals) at 0;
			write "[" + name + "]: " + currentPrice + ' accepted by ' + winner.sender + ".";
			//Announce winner with FIPA to the winner
			do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ["Winner", currentPrice]);
			//Stop auction
			do stopAuction;
			return;
		}
		//Nobody accepted, so lower the price
		currentPrice <- currentPrice - dutchPriceStep;
		//If the current price is more than or equal to the minimum price, propose it to the guests
		if(currentPrice >= dutchMinPrice){ 
			write "[" + name + "]: The guests rejected it, sending proposal " + currentPrice;
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: [currentPrice]);
			return;
		}
		//Otherwise it's lower than the minimum price we would sell it for, so stop the auction without a winner
		write "[" + name + "]: I can't go any lower...";
		do stopAuction;
		return;
	}
	
	/**
	 * Handle the responses for the English auction
	 */
	reflex handleEnglish when: auctionRunning and auctionType=1 and (!empty(reject_proposals) or !empty(accept_proposals)){
		loop p over: reject_proposals {
			//write "[" + name + "]: " + p.sender + "  didn't bid now.";
			remove p.sender from: interestedGuests;
		}
		//if everyone rejected the first offer, stop the auction
		if (length(interestedGuests) = 0 and highestCurrentBidder = nil){
			write "[" + name + "]: Nobody wanted to bid, so I'm stopping this auction";
			do stopAuction;
			return;
		}
		//Nobody or only 1 person bid in this round -> give it to the current highest bidder
		if (length(interestedGuests) = 0 or length(interestedGuests) = 1) {
			write "[" + name + "]: Auction won by " + highestCurrentBidder + " for " + currentPrice + ".";
			do start_conversation(to: [highestCurrentBidder], protocol: 'fipa-propose', performative: 'cfp', contents: ["Winner", currentPrice]);
			do stopAuction;
			return;
		}
		//Handle current bids
		loop p over: accept_proposals {
			int bid_price <- int(p.contents[0]);
			write "[" + name + "]: " + bid_price + ' bid by ' + p.sender + ".";
			if (bid_price > currentPrice){
				currentPrice <- bid_price;
				highestCurrentBidder <- p.sender;
			}
		}
		
		write "[" + name + "]: " + currentPrice + " is currently the highest bid";
		
		do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: [currentPrice]);
	}
	
	/**
	 * Handle the response for the Sealed-Bid Auction
	 */
	reflex handleSealedBid when: auctionRunning and auctionType=2 and !empty(accept_proposals){
		currentPrice <- 0;
		loop p over: accept_proposals {
			int bid_price <- int(p.contents[0]);
			write "[" + name + "]: " + bid_price + ' bid by ' + p.sender + ".";
			if (bid_price > currentPrice){
				currentPrice <- bid_price;
				highestCurrentBidder <- p.sender;
			}
		}
		write "[" + name + "]: " + highestCurrentBidder + " won with the highest bid of " + currentPrice + ".";
		do start_conversation(to: [highestCurrentBidder], protocol: 'fipa-propose', performative: 'cfp', contents: ["Winner", currentPrice]);
		do stopAuction;
	}
	
	/**
	 * Handle the responses for the Vickrey Auction
	 */
	reflex handleVickrey when: auctionRunning and auctionType=3 and !empty(accept_proposals){
		loop p over: accept_proposals {
			int bid_price <- int(p.contents[0]);
			write "[" + name + "]: " + bid_price + ' bid by ' + p.sender + ".";
			if (bid_price >= currentPrice){
				vickreySecondHighest <- currentPrice;
				currentPrice <- bid_price;
				highestCurrentBidder <- p.sender;
			} 
			if (bid_price < currentPrice and bid_price>=vickreySecondHighest){
				vickreySecondHighest <- bid_price;
			}
		}
		write "[" + name + "]: " + highestCurrentBidder + " won with the highest bid of " + currentPrice + ", and has to pay " + vickreySecondHighest + ".";
		do start_conversation(to: [highestCurrentBidder], protocol: 'fipa-propose', performative: 'cfp', contents: ["Winner", vickreySecondHighest]);
		do stopAuction;
	}
	
	aspect base {
		draw triangle(3) color: rgb('gray');
	}
}