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
 */
species Guest skills: [moving]{
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
	
	bool shallBeRemoved <- false;
	
	/**
	 * The store, where the current needs of the guest can be served.
	 * If the guest does not need anything, it is nil.
	 */
	Store goal_store <- nil;
	
	list<Store> visited_stores <- [];
	
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
	reflex allGood when: ((!thirsty and !hungry) or shallBeRemoved){
		do wander;
	}
	
	/**
	 * When the Guest is hungry or thirsty and is away from Information Center and not walking towards a Store, it should move to the Information Center.
	 */
	reflex goToInfoCenter when: ((thirsty or hungry) and self distance_to infocenter_location >= distance_threshold and goal_store = nil and !shallBeRemoved){
		if (empty(visited_stores)) {
			do goto target: infocenter_location;
		} else {
			float ask_for_different <- rnd(0.0, 10.0);
			
			if (ask_for_different <= 9.0) {
				do goto target: infocenter_location;
			} else {
				int random_store <- rnd(length(visited_stores)-1);
				goal_store <- visited_stores[random_store];
			} 
		}	
	}
	
	/**
	 * When the Guest is hungry or thirsty and is at the Information Center, it asks for a Store with the required services (food or drink) to fulfill its needs.
	 */
	reflex atInfoCenter when: ((thirsty or hungry) and self distance_to infocenter_location < distance_threshold and goal_store = nil and !shallBeRemoved){
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
	reflex goToGoalStore when: ((thirsty or hungry) and goal_store != nil and self distance_to goal_store >= distance_threshold){
		do goto target: self.goal_store.location;
	}
	
	/**
	 * When the Guest is hungry or thirsty and at the Store that can fulfill its needs, it should buy the needed items.
	 */
	reflex buyStuff when: ((thirsty or hungry) and goal_store != nil and self distance_to goal_store < distance_threshold){
		Store a <- goal_store.buy(self);
		//write name + ": " + goal_store;
		if extra_small_brain and !(visited_stores contains goal_store) { //store the visited store if guest have small memory
			add goal_store to: visited_stores;
			//write name + ": " + visited_stores;
		}
		goal_store <- nil;
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
	 * Removes this Guest from the festival.
	 */
	action removeFromFestival {
		write name + ": I am a bad guy and I got what I deserved. Goodbye!";
		num_guest <- num_guest - 1;
		do die;
	}
}