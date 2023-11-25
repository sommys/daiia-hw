/**
* Name: guest
* Description: Guest species for the homework project
* Author: Andreas Naoum, Soma Seres
*/

model guest

import "global_species.gaml"

global{
	/**
	 * Maximum value for thirst level
	 */
	float thirst_max <- 100.0;
	
	/**
	 * Maximum value for hunger level
	 */
	float hunger_max <- 100.0;
}

/**
 * The species representing the guests of the festival.
 * It has the moving skill, so it can wander and move to the Information Center and Stores.
 * It has the fipa skill, so it can send the auctioneer responses about taking part in the auctions and communicate during the auction.
 */
species Guest skills: [moving, fipa]{
	/** 
	 * Value that is responsible for decreasing the values for thirst.
	 * It is randomly generated between 0 and 1 (everyone is different).
	 */
	float thirst_step <- rnd(0.0, 1.0);
	
	/** 
	 * Value that is responsible for decreasing the values for hunger.
	 * It is randomly generated between 0 and 1 (everyone is different).
	 */
	float hunger_step <- rnd(0.0, 1.0);
	
	/**
	 * Threshold value for the thirst level, responsible for signaling the guest if they are thirsty.
	 * It is randomly generated between 10 and 20 (everyone is different).
	 */
	float thirst_threshold <- rnd(10.0, 20.0);
	
	/**
	 * Threshold value for the hunger level, responsible for signaling the guest if they are hungry.
	 * It is randomly generated between 10 and 20 (everyone is different).
	 */
	float hunger_threshold <- rnd(10.0, 20.0);
	
	/**
	 * Value for the thirst level, responsible for keeping track of how thirsty the guest is.
	 * It is starting from the maximum value defined by thirst_max and the minimum value is 0.
	 * In each step it is decreased by the thirst_step.
	 */
	float thirst_value <- thirst_max min: 0.0 update: thirst_value - thirst_step;
	
	/**
	 * Value for the hunger level, responsible for keeping track of how hungry the guest is.
	 * It is starting from the maximum value defined by hunger_max and the minimum value is 0.
	 * In each step it is decreased by the thirst_step.
	 */
	float hunger_value <- hunger_max min: 0.0 update: hunger_value - hunger_step;
	
	/**
	 * Flag representing if the guest is thirsty (the thirst level is under the threshold)
	 * It only gets updated if the guest is not hungry, as the guest can only focus on one problem at a time, unless they reach both states at the same time.
	 */
	bool thirsty <- false update: hungry ? thirsty : thirst_value < thirst_threshold;
	
	/**
	 * Flag representing if the guest is hungry (the hunger level is under the threshold)
	 * It only gets updated if the guest is not thirsty, as the guest can only focus on one problem at a time, unless they reach both states at the same time.
	 */
	bool hungry <- false update: thirsty ? hungry : hunger_value < hunger_threshold;
	
	/**
	 * The store, where the current needs of the guest can be served.
	 * If the guest does not need anything, it is nil.
	 */
	Store goal_store <- nil;
	
	/**
	 * The list of already visited stores (if guests have small brain).
	 */
	list<Store> visited_stores <- [];
	
	/**
	 * Flag to make sure we only try to go to a random already visited store once when the agent turns hungry/thirsty.
	 */
	bool triedRandomGeneration <- false;
	
	/**
	 * Flag for marking the agent as a bad behavior guest, so it appears differently in the simulation.
	 */
	bool shallBeRemoved <- false;
	
	/**
	 * The location of the auction that the guest wants to take part in.
	 */
	point auctionLocation <- nil;
	
	/**
	 * The maximum price for the current auction the guest is willing to pay.
	 */
	int maxPrice <- 0;
	
	/**
	 * The chance threshold for the guest to bid in an English auction
	 */
	int bid_threshold <- 0;
	
	/**
	 * The preferred item for the guest, the only item it is willing to pay for.
	 */
	string preferredItem <- one_of(possibleItems);
	
	/**
	 * The currently running auction's type (Dutch/English/Sealed-Bid/Vickrey)
	 */
	string auctionType <- "";
	
	/**
	 * The graphical representation of the Guest species.
	 */
 	aspect base {
		//By default they are green when everything is ok
		color <- rgb("green");
		if (shallBeRemoved) { //In case the agent shall be removed from the festival, they turn purple
			color <- rgb(128,0,128);
		} else if(hungry and thirsty){ //In case they are both hungry and thirsty, they turn red
			color <- rgb("red");
		} else if(hungry){ //In case they are only hungry, they turn to pastel orange
			color <- rgb(255, 179, 71);
		} else if(thirsty){ //In case they are only thirsty, they turn to pastel blue
			color <- rgb(167, 199, 231);
		}
		//The representation is a small circle
		draw circle(1) color: color;
	}
	
	/**
	 * When the Guest is neither hungry nor thirsty, or it has became upset (and shall be kicked) he just wanders around.
	 */
	reflex allGood when: auctionLocation = nil and ((!thirsty and !hungry) or shallBeRemoved){
		do wander;
	}
	
	/**
	 * Whenever the guest has a message in the cfps list, process it and act accordingly
	 * Start -> saves the location and sets their maximum price
	 * Stop -> they leave the location
	 * Win -> they say that they have won
	 */
	reflex auctionInfo when: (!empty(cfps)){
		//Get the most recent message
		message msg <- cfps at 0;
		//Get the subject of the message
		string subject <- msg.contents[0];
		if (subject = "Start") {
			//Get the auction type
			auctionType <- msg.contents[1];
			//If we don't have multiple items, do not care about the sold item
			if(!extra_multi_items){
				//Save the location of the auction to navigate there
				auctionLocation <- msg.contents[2];
				//Calculate maxPrice if necessary for the current auction type
				int sellingPrice <- int(msg.contents[3]);
				if (auctionType="Dutch"){
					maxPrice <- round(sellingPrice * rnd(0.5, 0.8));
				} 
				else if (auctionType="English") {
					maxPrice <- round(sellingPrice * rnd(1.5, 1.8));	
				} else if (auctionType="Sealed-Bid") {
					maxPrice <- round(sellingPrice * 1.25);
				} else if (auctionType="Vickrey") {
					maxPrice <- round(sellingPrice * 1.5);
				}
				return;
			}
			//If we have multiple items, get the item
			string item <- msg.contents[4];
			
			string response <- "Not interested";
			//Only care about our preferred item's auction
			if(item = preferredItem){
				//Save location and calculate maxPrice if needed
				auctionLocation <- msg.contents[2];
				int sellingPrice <- int(msg.contents[3]);
				if (auctionType="Dutch"){
					maxPrice <- round(sellingPrice * rnd(0.5, 0.8));
				} 
				else if (auctionType="English") {
					maxPrice <- round(sellingPrice * rnd(1.5, 1.8));	
				}
				response <- "Interested";
			}
			//Respond to the auctioneer with the appropriate answer (Interested/Not interested) for the auction
			do start_conversation (to: msg.sender, protocol: 'fipa-propose', performative: 'cfp', contents: [response]);
		}
		//Only handle stop if it is about our interested auction in case of multi-items available.
		else if(subject = "Stop" and (!extra_multi_items or msg.contents[1] = preferredItem)) {
			//Note the end of the auction by setting the auctionLocation to nil, so the guest can continue having fun.
			auctionLocation <- nil;
		}
		else if(subject = "Winner"){
			write "[" + name + "]: I won!!";
			int gain <- maxPrice - int(msg.contents[1]);
			write "[" + name + "]: Gained value for me: " + gain;
		}
	}
	
	/**
	 * Whenever there is an auction the guest is interested in, and is not near the auction, go towards it
	 */
	reflex goToAuction when: auctionLocation != nil and location distance_to(auctionLocation) > distance_threshold{
		do goto target:auctionLocation;
	}
	
	/**
	 * Replying to the proposals of the auctioneer for currently running auction
	 */
	reflex replyPropose when: auctionLocation != nil and !empty(proposes){
		//Get the most recent proposal
		message proposal <- proposes at 0;
		int currentPrice <- int(proposal.contents[0]);
		if (auctionType="Dutch"){
			//Check if the current price is acceptable for us or not yet, and reject/accept based on the current value
			if(currentPrice >= maxPrice){
				do reject_proposal (message: proposal, contents: ["Rejected"]);
			} else {
				do accept_proposal (message: proposal, contents: ["Accepted"]);
			}
		}
		else if (auctionType="English"){
			//Get the current highest bid and increase it by 5-15%
			int bid_price <- round(currentPrice * rnd(1.05,1.15));
			
			// Based on randmoness, a threshold is used and it's increased every round
			bid_threshold <- bid_threshold + rnd(1,10);
			int bid_random <- rnd(1, 100);
			
			// Decide if we want to bid based on the current proposal and the randomness
			if (bid_price <= maxPrice and bid_random > bid_threshold){
				do accept_proposal (message: proposal, contents: [bid_price]);
			} else {
				do reject_proposal (message: proposal, contents: ["Rejected"]);
			}			
		}
		else if (auctionType="Sealed-Bid"){
			//Generate bid and send it as our proposal
			int bid_price <- round(currentPrice * rnd(1.05,1.25));
			do accept_proposal (message: proposal, contents: [bid_price]);
		}
		else if (auctionType="Vickrey"){
			//Generate bid and send it as our proposal
			int bid_price <- round(currentPrice * rnd(1.05,1.5));
			do accept_proposal (message: proposal, contents: [bid_price]);
		}
	}
	
	/**
	 * When the Guest is hungry or thirsty and is away from Information Center and not walking towards a Store, it should move to the Information Center.
	 */
	reflex goToInfoCenter when: auctionLocation = nil and ((thirsty or hungry) and self distance_to infocenter_location >= distance_threshold and goal_store = nil and !shallBeRemoved){
		//Try randomly going to an already visited store only once
		if(!triedRandomGeneration){
			triedRandomGeneration <- true;
			if(wantKnown()){ //if the agent wants to go to a known place, find an eligible one
				goal_store <- eligibleKnown();
				if(goal_store != nil){ //if we could find a store, return from this reflex, to prevent inneccessarily moving towards the information center
					return;
				}
			}
		}
		
		do goto target: infocenter_location;
	}
	
	/**
	 * When the Guest is hungry or thirsty and is at the Information Center, it asks for a Store with the required services (food or drink) to fulfill its needs.
	 */
	reflex atInfoCenter when: auctionLocation = nil and ((thirsty or hungry) and self distance_to infocenter_location < distance_threshold and goal_store = nil and !shallBeRemoved){
		ask InformationCenter{
			myself.goal_store <- self.askForStore(myself, myself.hungry, myself.thirsty);
		}
		if (goal_store=nil) { //if the InformationCenter doesn't give the guest a store to go to, it makes a scene, and has to be removed from the festival
			write name + ": What do you mean you don't give me a store?? This is unnacceptable!!!";
		}
	}
	
	/**
	 * When the Guest is hungry or thirsty and knows the Store that is closest and can fulfill its needs, it should move towards that Store.
	 */
	reflex goToGoalStore when: auctionLocation = nil and ((thirsty or hungry) and goal_store != nil and self distance_to goal_store >= distance_threshold){
		do goto target: self.goal_store.location;
	}
	
	/**
	 * When the Guest is hungry or thirsty and at the Store that can fulfill its needs, it should buy the needed items.
	 */
	reflex buyStuff when: auctionLocation = nil and ((thirsty or hungry) and goal_store != nil and self distance_to goal_store < distance_threshold){
		Store _ <- goal_store.buy(self);
		if extra_small_brain and !(visited_stores contains goal_store) { //store the visited store if guest have small memory
			add goal_store to: visited_stores;
		}
		goal_store <- nil;
		triedRandomGeneration <- false;
	}
	
	/**
	 * Action responsible for setting the hunger and thirst values based on the offered services of the Store and the current state of the Guest.
	 */
	action refill(bool food, bool drink){
		if (food and hungry) {
			self.hunger_value <- hunger_max;
		}
		if (drink and thirsty) {
			self.thirst_value <- thirst_max;
		}
	}
	
	/**
	 * Helper method for determining if the agent wants an already visited store.
	 */
	bool wantKnown{
		return !empty(visited_stores) and rnd(0.0, 1.0) < known_threshold;
	}
	
	/**
	 * Helper method for finding an eligible store that the guest already visited and has the required services.
	 */
	Store eligibleKnown{
		loop s over: shuffle(visited_stores){ //randomize order and look through all visited stores
			//select the one with the required needs
			if((hungry and thirsty and s.hasFood and s.hasDrink) or (hungry and !thirsty and s.hasFood) or (!hungry and thirsty and s.hasDrink)){
				return s;
			}
		}
		return nil;
	}
	
	/**
	 * Removes this Guest from the festival.
	 */
	action removeFromFestival {
		write name + ": I am a bad guy and I got what I deserved. Goodbye!";
		num_guest <- num_guest - 1;
		do die;
	}
}