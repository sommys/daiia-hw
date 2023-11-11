/**
* Name: securityguard
* Based on the internal empty template. 
* Author: Andreas Naoum, Soma Seres
* Tags: 
*/


model securityguard

import "global_species.gaml"
import "guest.gaml"

global{
	/**
	 * Maximum value for thirst level
	 */
	float check_max <- 100.0;
	
}

species Guard skills: [moving]{
	
	
	float check_step <- rnd(0.0, 2.0);
	
	float check_threshold <- rnd(10.0, 20.0);
	
	float check_value <- check_max min: 0.0 update: check_value - check_step;
	
	bool check_time <- false update: check_value < check_threshold;
	
	Guest bad <- nil;
	
	reflex allGood when: (bad=nil){
		do wander;
	}
	
	reflex goToInfoCenter when: ((check_time) and self distance_to infocenter_location >= distance_threshold and self.bad = nil){
		// write "I'm going to Info Center";
		do goto target: infocenter_location;	
	}
	
	reflex atInfoCenter when: ((check_time) and self distance_to infocenter_location < distance_threshold and self.bad = nil){
		write "Asking Info Center for bad guys";
		ask InformationCenter{
			myself.bad <- self.ask_for_bad_guy();
		}
		if (!(bad=nil)) {
			bad <- bad.please_die();
		}
		bad <- nil;
		self.check_value <- check_max;
		do goto target: (infocenter_location+{1000,1000});
	}
	
	aspect base {
		//By default they are green when everything is ok
		color <- rgb("black");
		//The representation is a small circle
		draw circle(3) color: color;
	}
	
}