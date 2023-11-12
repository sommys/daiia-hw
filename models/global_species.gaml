/**
* Name: global_species
* Global species for the project 
* Author: Andreas Naoum, Soma Seres
*/
model global_species

import "guest.gaml"
import "information_center.gaml"
import "store.gaml"
import "security_guard.gaml"

global{
	//make sure the shape is a 200x200 rectangle for same results over experiments
	geometry shape <- polygon ([{0.0,200.0,0.0},{200.0,200.0,0.0},{200.0,0.0,0.0},{0.0,0.0,0.0},{0.0,200.0,0.0}]);
	/**
	 * Number of guests at the festival
	 */
	int num_guest <- 10;
	
	/**
	 * Number of stores at the festival
	 */
	int num_store <- 4;
	
	/**
	 * Number of security guards at the festival
	 */
	int num_guards <- 1;
	
	/**
	 * Threshold for distance when going to a target location
	 */
	float distance_threshold <- 0.5;
	
	/**
	 * Global variable for the location of the single InformationCenter of the festival (everyone knows it)
	 */
	point infocenter_location <- nil;
	
	/**
	 * Flag for turning the small brain of the guests on and off (Challenge 1)
	 */
	bool extra_small_brain <- true;
	
	/**
	 * Chance for visiting a known store instead of a new one if guests have small brain.
	 */
	float known_threshold <- 0.75;
	
	/**
	 * Flag for turning the bad behavior of guests on and off (Challenge 2)
	 */
	bool extra_bad_behavior <- false;
	
	/**
	 * Chance for triggering the bad behavior for the guests
	 */
 	float bad_behavior_threshold <- 0.05;
	
	/**
 	 * Tracker for total distance traveled by the guests
 	 */
 	float totalDistanceTraveled <- 0.0;
	
	init{
		create InformationCenter;
		create Store number:num_store;
		//layout stores in a 100x100 rectangle
		int i <- 0;
		loop s over: Store{
			if(i = 0){
				s.hasFood <- false;
				s.hasDrink <- false;
				s.location <- point({50.0, 50.0});
			} else if(i = 1){
				s.hasFood <- true;
				s.hasDrink <- false;
				s.location <- point({50.0, 150.0});
			} else if(i = 2){
				s.hasFood <- false;
				s.hasDrink <- true;
				s.location <- point({150.0, 50.0});
			} else {
				s.hasFood <- true;
				s.hasDrink <- true;
				s.location <- point({150.0, 150.0});
			}
			i <- i+1;
		}
		create Guest number:num_guest;
		if (extra_bad_behavior){ //only create guards if the bad behavior is turned on
			create SecurityGuard number:num_guards;
		}
		ask InformationCenter{
			self.location <- point({100.0, 100.0}); //make sure the InformationCenter is in the middle
			infocenter_location <- self.location; //save the location of the InformationCenter inside the global variable
		}
	}
	
	/**
	 * Stop the simulation if there are no guests at the festival
	 */
	reflex stop_simulation when: num_guest <= 0 {
       do pause;
    }
}

experiment festivalExperiment type:gui {
	output {
			display myDisplay {
				species InformationCenter aspect: base;
				species Guest aspect:base;
				species Store aspect:base;
				species SecurityGuard aspect:base;
			}
			monitor "Avg Traveled Distance" value: totalDistanceTraveled / num_guest; //measure avg distance by guests
		}
}