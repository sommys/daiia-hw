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
	bool extra_multi_items <- true;
	
	/**
	 * Possible items for sale at the festival on auctions
	 */
 	// list<string> possibleItems <- ["CD", "Bag", "T-shirt", "Hoodie"];
 	
 	list<string> possibleItems <- ["CD"];
 	
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
					do startAuction;
				}
			}
		} else {
			create Auctioneer{
				do startAuction;
			}
		}
	}
}

species Auctioneer skills:[fipa]{
	
		/**
	 * Flag for testing different scenarios for different types of auctions (Homework 2, Challenge 2)
	 * 0 <- Random
	 * 1 <- 1000
	 * 2 <- 5000
	 * 3 <- 100000
	 */
	int test_scenario <- 0;
	
	// Auction Types
	// 0 <- Dutch 
	// 1 <- English 
	// 2 <- Sealed-Bid 
	// 3 <- Vickrey 
	int auctionType <- 0;
	
	bool auctionRunning <- false;
	int realValue <- rnd(1000, 1500);
	int currentPrice <- round(realValue * rnd(1.5, 2.0));
	int minPrice <- round(realValue * rnd(0.8, 0.9));
	int priceStep <- round(realValue * 0.05);
	
	// int lowestAcceptablePrice <- 1500;
	int highestCurrentBid <- round(realValue * rnd(0.8, 0.9));
	
	int firstHighest <- 0;
	int secondHighest <- 0;
	
	Guest highestCurrentBidder <- nil;
	
	int valueEstimation <- 1500;
	
	string sellingItem <- nil;
	list<Guest> interestedGuests <- [];
	
	list<Guest> activeGuests <- [];
	
	list<Guest> notActiveGuests <- [];
	
	int processed <- 0;
	
	string getAuctionText(int type){
		if (auctionType = 0) {
			return "Dutch";
		}
		else if (auctionType = 1) {
			return "English";
		} 
		else if (auctionType = 2) {
			return "Sealed-Bid";
		}
		return "Vickrey";
		
	}
	
	int getPriceToStart(int type){
		if (auctionType = 0) {
			return currentPrice;
		}
		else if (auctionType = 1) {
			return highestCurrentBid;
		} 
		else if (auctionType = 2) {
			return currentPrice;
		}
		return currentPrice;
		
	}
	
	bool setScenario(int scenario) {
		
		if (scenario = 1){
			
			if (auctionType = 0) {
				realValue <- 1000;
				currentPrice <- 1700;
				minPrice <- 800;
				priceStep <- round(realValue * 0.05);
			}
			else if (auctionType = 1) {
				highestCurrentBid <- 800;
			} 
			else {
				currentPrice <- 1000;
			}

		} 
		else if (scenario = 2){
			if (auctionType = 0) {
				realValue <- 5000;
				currentPrice <- 8000;
				minPrice <- 4000;
				priceStep <- round(realValue * 0.05);
			}
			else if (auctionType = 1) {
				highestCurrentBid <- 4000;
			} 
			else {
				currentPrice <- 5000;
			}
		}
		else {
			if (auctionType = 0) {
				realValue <- 100000;
				currentPrice <- 120000;
				minPrice <- 80000;
				priceStep <- round(realValue * 0.05);
			}
			else if (auctionType = 1) {
				highestCurrentBid <- 100000;
			} 
			else {
				currentPrice <- 100000;
			}
		}
		return true;
	}
	
	action startAuction {
		if (test_scenario > 0) {
			bool s <- setScenario(test_scenario);
		}
		write "["+name+"]: Hey dear guests! " + getAuctionText(auctionType) +  "Auction starting " + (extra_multi_items ? ("for " + sellingItem) : "") + " soon at (" + int(location.x) + ";" + int(location.y) + ")!";
		// do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ["Start", location, currentPrice, sellingItem]);
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ["Start", getAuctionText(auctionType), location, getPriceToStart(auctionType), sellingItem]);
		if(!extra_multi_items){
			interestedGuests <- list(Guest);
		}
	}
	
	action stopAuction {
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop", sellingItem]);
		auctionRunning <- false;
		write "[" + name + "]: Auction is over, goodbye!";
		do die;
	}
	
	reflex auctionInfo when: extra_multi_items and !empty(cfps){
		message msg <- cfps at 0;
		if(msg.contents[0] = "Interested"){
			add item: msg.sender to: interestedGuests;
		}
		processed <- processed + 1;
	}
	
	reflex cancelAuction when: !auctionRunning and extra_multi_items and processed = num_guest and length(interestedGuests) = 0 {
		do stopAuction;
	}
	
	reflex canStartAuction when: !auctionRunning and (!extra_multi_items or processed = num_guest) and length(interestedGuests) > 0 and interestedGuests max_of (location distance_to(each.location)) < distance_threshold{
		auctionRunning <- true;
		// write "[" + name + "]: Starting with proposal " + currentPrice;
		write "[" + name + "]: Starting with proposal " + getPriceToStart(auctionType);
		do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: [getPriceToStart(auctionType)]);
	}
	
	reflex receiveRejections when: auctionRunning and !empty(reject_proposals){
		
		if (auctionType=0){
			currentPrice <- currentPrice - priceStep;
			if(currentPrice < minPrice){
				write "[" + name + "]: I can't go any lower...";
				do stopAuction;
			} else {
				write "[" + name + "]: The guests rejected it, sending proposal " + currentPrice;
				do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: [currentPrice]);
			}
		} 
		else if (auctionType=1){
			loop p over: reject_proposals {
				write "[" + name + "]: " + p.sender + "  didn't bid now.";
				if !(notActiveGuests contains p.sender){
					add p.sender to: notActiveGuests;
				}
			}
			
			if (length(notActiveGuests) = length(interestedGuests)) {
				write "[" + name + "]: " + highestCurrentBid + ' winned by ' + highestCurrentBidder + ".";
				// do start_conversation(to: highestCurrentBidder, protocol: 'fipa-propose', performative: 'cfp', contents: ["Winner"]);
				do stopAuction;
			}
		} 
	}
	
	reflex receiveAccept when: auctionRunning and !empty(accept_proposals) {
		if (auctionType=0){
			message winner <- shuffle(accept_proposals) at 0;
			write "[" + name + "]: " + currentPrice + ' accepted by ' + winner.sender + ".";
			do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ["Winner"]);
			do stopAuction;
		} 
		else if (auctionType=1){
			loop p over: accept_proposals {
				
				if (notActiveGuests contains p.sender){
					remove p.sender from: notActiveGuests;
				}
				
				int bid_price <- int(p.contents[0]);
				write "[" + name + "]: " + bid_price + ' bidded by ' + p.sender + ".";
				if (bid_price > highestCurrentBid){
					highestCurrentBid <- bid_price;
					highestCurrentBidder <- p.sender;
				}
			}
			write "[" + name + "]: " + highestCurrentBid + " highest bid";
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: [highestCurrentBid]);
		}
		else if (auctionType=2){
			loop p over: accept_proposals {
				int bid_price <- int(p.contents[0]);
				write "[" + name + "]: " + bid_price + ' bidded by ' + p.sender + ".";
				if (bid_price > firstHighest){
					firstHighest <- bid_price;
					highestCurrentBidder <- p.sender;
				}
			}
			write "[" + name + "]: " + highestCurrentBidder + " highest bid with amount: " + firstHighest;
			do stopAuction;
		}
		else if (auctionType=3){
			loop p over: accept_proposals {
				int bid_price <- int(p.contents[0]);
				write "[" + name + "]: " + bid_price + ' bidded by ' + p.sender + ".";
				if (bid_price >= firstHighest){
					secondHighest <- firstHighest;
					firstHighest <- bid_price;
					highestCurrentBidder <- p.sender;
				} 
				if (bid_price < firstHighest and bid_price>=secondHighest){
					secondHighest <- bid_price;
				}
			}
			write "[" + name + "]: " + highestCurrentBidder + " highest bid with amount: " + secondHighest;
			do stopAuction;
		}
	}
	
	aspect base {
		draw triangle(3) color: rgb('gray');
	}
}