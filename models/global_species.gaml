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
	
	bool extra_small_brain <- true;
	
	bool extra_bad_behavior <- true;
	
	init{
		create InformationCenter;
		create Store number:num_store;
		create Guest number:num_guest;
		if (extra_bad_behavior){
			create Guard number:num_guards;
		}
		ask InformationCenter{
			infocenter_location <- self.location; //save the location of the InformationCenter inside the global variable
		}
	}
}

experiment myExperiment type:gui {
	output {
			display myDisplay {
				species InformationCenter aspect: base;
				species Guest aspect:base;
				species Store aspect:base;
				species Guard aspect:base;
			}	
		}
}