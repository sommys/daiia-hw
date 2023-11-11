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
	 * It is randomly generated between 1 and 5 (everyone is different).
	 */
	float thirst_step <- rnd(0.0, 1.0);
	
	/** 
	 * Value that is responsible for decreasing the values for hunger.
	 * It is randomly generated between 1 and 5 (everyone is different).
	 */
	float hunger_step <- rnd(0.0, 1.0);
	
	/**
	 * Threshold value for the thirst level, responsible for signaling the guest if they are thirsty.
	 * It is randomly generated between 25 and 50 (everyone is different).
	 */
	float thirst_threshold <- rnd(10.0, 20.0);
	
	/**
	 * Threshold value for the hunger level, responsible for signaling the guest if they are hungry.
	 * It is randomly generated between 25 and 50 (everyone is different).
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
	
	bool willBeKilled <- false;
	
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
		if (willBeKilled) {
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
	 * When the Guest is neither hungry nor thirsty, he just wanders around having a good time.
	 */
	reflex allGood when: (!thirsty and !hungry and !willBeKilled){
		do wander;
	}
	
	/**
	 * When the Guest is hungry or thirsty and is away from Information Center and not walking towards a Store, it should move to the Information Center.
	 */
	reflex goToInfoCenter when: ((thirsty or hungry) and self distance_to infocenter_location >= distance_threshold and self.goal_store = nil and !willBeKilled){
		if (empty(visited_stores)) {
			do goto target: infocenter_location;
		} else {
			float ask_for_different <- rnd(0.0, 10.0);
			
			if (ask_for_different <= 9.0) {
				do goto target: infocenter_location;
			} else {
				int random_store <- rnd(length(visited_stores)-1);
				// write "Random: "+int(random_store)+" length: "+ length(visited_stores);
				goal_store <- visited_stores[random_store];
			} 
		}	
	}
	
	/**
	 * When the Guest is hungry or thirsty and is at the Information Center, it asks the closest Store with the required services (food or drink) to fulfill its needs.
	 */
	reflex atInfoCenter when: ((thirsty or hungry) and self distance_to infocenter_location < distance_threshold and self.goal_store = nil and !willBeKilled){
		
		if extra_small_brain {
			
			if (empty(visited_stores)){
				ask InformationCenter{
					myself.goal_store <- self.closest_store_with_supply(myself, myself.location, myself.hungry, myself.thirsty);
				}
			} else {
				ask InformationCenter{
					myself.goal_store <- self.different_store_with_supply(myself, myself.visited_stores, myself.location, myself.hungry, myself.thirsty);
				}
			}
			
			if (goal_store=nil) {
				willBeKilled <- true;
				write "I will be dead soon";
			} else {
				add goal_store to: visited_stores;
			}
			
		} else {
			ask InformationCenter{
				myself.goal_store <- self.closest_store_with_supply(myself, myself.location, myself.hungry, myself.thirsty);
			}
		}
	}
	
	/**
	 * When the Guest is hungry or thirsty and knows the Store that is closest and can fulfill its needs, it should move towards that Store.
	 */
	reflex goToGoalStore when: ((thirsty or hungry) and self.goal_store != nil and self distance_to self.goal_store >= distance_threshold and !willBeKilled){
		do goto target: self.goal_store.location;
	}
	
	/**
	 * When the Guest is hungry or thirsty and at the Store that can fulfill its needs, it should buy the needed items.
	 */
	reflex buyStuff when: ((thirsty or hungry) and goal_store != nil and self distance_to goal_store < distance_threshold and !willBeKilled){
		goal_store <- goal_store.buy(self);
		goal_store <- nil;
	}
	
	/**
	 * Action responsible for setting the hunger and thirst values based on the offered services of the Store and the current state of the Guest.
	 */
	action refill(bool food, bool drink){
		if(food and hungry){
			self.hunger_value <- hunger_max;
		}
		if(drink and thirsty){
			self.thirst_value <- thirst_max;
		}
	}
	
	action please_die {
		write "I am a bad guy and I got what I deserved. Goodbye!";
		do die;
	}
}