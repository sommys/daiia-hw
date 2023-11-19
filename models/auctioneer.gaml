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
	 * Flag for turning the multiple items for auctions on and off (Homework2, Challenge 1)
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
	
	bool auctionRunning <- false;
	int realValue <- rnd(1000, 1500);
	int currentPrice <- round(realValue * rnd(1.5, 2.0));
	int minPrice <- round(realValue * rnd(0.8, 0.9));
	int priceStep <- round(realValue * 0.05);
	
	string sellingItem <- nil;
	list<Guest> interestedGuests <- [];
	int processed <- 0;
	
	action startAuction{
		write "["+name+"]: Hey dear guests! Auction starting for " + sellingItem + " soon at (" + int(location.x) + ";" + int(location.y) + ")!";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ["Start", location, currentPrice, sellingItem]);
		if(!extra_multi_items){
			interestedGuests <- list(Guest);
		}
	}
	
	action stopAuction{
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
	
	reflex cancelAuction when: !auctionRunning and extra_multi_items and processed = num_guest and length(interestedGuests) = 0{
		do stopAuction;
	}
	
	reflex canStartAuction when: !auctionRunning and (!extra_multi_items or processed = num_guest) and length(interestedGuests) > 0 and interestedGuests max_of (location distance_to(each.location)) < distance_threshold{
		auctionRunning <- true;
		write "[" + name + "]: Starting with proposal " + currentPrice;
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'propose', contents: [currentPrice]);
	}
	
	reflex receiveRejections when: auctionRunning and !empty(reject_proposals){
		currentPrice <- currentPrice - priceStep;
		if(currentPrice < minPrice){
			write "[" + name + "]: I can't go any lower...";
			do stopAuction;
		} else {
			write "[" + name + "]: The guests rejected it, sending proposal " + currentPrice;
			do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'propose', contents: [currentPrice]);
		}
	}
	
	reflex receiveAccept when: auctionRunning and !empty(accept_proposals){
		message winner <- shuffle(accept_proposals) at 0;
		write "[" + name + "]: " + currentPrice + ' accepted by ' + winner.sender + ".";
		do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ["Winner"]);
		do stopAuction;
	}
	
	aspect base{
		draw triangle(3) color: rgb('gray');
	}
}