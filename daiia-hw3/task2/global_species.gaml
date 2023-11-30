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
	int num_guest <- 5;
	int num_stage <- 3;
	
	int time_concert <- 100;
	int time_setup <- 25;
	int time_countdown <- 50;
	
	float concert_distance_threshold <- 4.0;
	
	list<string> concert_attribs <- ['band', 'light', 'sound', 'visual'];
	
	init{
		create Guest number: num_guest;
		create Stage number: num_stage;
	}
}

experiment festivalStages type: gui{
	output{
		display Festival{
			species Stage;
			species Guest;
		}
	}
}