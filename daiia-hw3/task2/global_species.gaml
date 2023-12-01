/**
* Name: global_species
* Global species for the festival project
* Author: Andreas Naoum, Soma Seres
*/

model global_species

import "guest.gaml"
import "stage.gaml"

/**
 * Global species for the festival project
 */
global{
	int num_guest <- 30;
	int num_stage <- 5;
	
	int time_concert <- 300;
	int time_setup <- 25;
	int time_countdown <- 50;
	
	float concert_distance_threshold <- 4.0;
	
	float leader_distance_threshold <- 6.0;
	
	// boolean variable to enable crowd mass challenge 
	bool crowd_mass_enabled <- true;
	Guest leader <- nil;
	
	float global_utility_before <- 0.0;
	float global_utility_after <- 0.0;
	
	list<string> concert_attribs <- ['band', 'songs', 'show', 'light', 'sound', 'visual'];
	
	init {
		create Guest number: num_guest;
		create Stage number: num_stage;
		create Entrance number: 1;
		
		// initialise the leader
		if (crowd_mass_enabled){
			leader <- list(Guest) at 0;
			write "Leader is " + leader;
		}
	}
}
species Entrance {
	
	init {
		location <- {50,75};
	}
	
	aspect base {
		draw square(3.0) color: rgb("blue");
		string label <- "Entrance";
		draw label size: 3 color: #white anchor: {0.5,0.5} font: font("Helvetica", 12 , #bold);
	}
	
}


experiment festivalStages type: gui{
	output{
		display Festival{
			species Stage;
			species Guest;
			species Entrance;
		}
	}
}