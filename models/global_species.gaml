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
	/**
	 * Number of guests at the festival
	 */
	int num_guest <- 20;
	
	/**
	 * Number of stores at the festival
	 */
	int num_store <- 6;
	
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
	 * Flag for turning the bad behavior of guests on and off (Challenge 2)
	 */
	bool extra_bad_behavior <- true;
	/**
	 * Chance for triggering the bad behavior for the guests
	 */
 	float bad_behavior_threshold <- 0.05;
	
	init{
		create InformationCenter;
		create Store number:num_store;
		create Guest number:num_guest;
		if (extra_bad_behavior){ //only create guards if the bad behavior is turned on
			create SecurityGuard number:num_guards;
		}
		ask InformationCenter{
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
		}
}