/**
* Name: global_species
* Global species for the festival project
* Author: Andreas Naoum, Soma Seres
*/

model global_species

import "guest.gaml"
import "stage.gaml"
import "leader.gaml"

/**
 * Global species for the festival project
 */
global{
	int num_guest <- 50;
	int num_stage <- 3;
	
	int time_concert <- 100;
	int time_setup <- 25;
	int time_countdown <- 50;
	
	float concert_distance_threshold <- 4.0;
	
	float leader_distance_threshold <- 6.0;
	
	// boolean variable to enable crowd mass challenge 
	bool crowd_mass_enabled <- false;
	list<Guest> allGuests <- [];
	Guest leader <- nil;
	
	list<string> concert_attribs <- ['band', 'songs', 'show', 'light', 'sound', 'visual'];
	
	init {
		if(crowd_mass_enabled){
			create Leader;			
		}
		create Guest number: crowd_mass_enabled ? num_guest-1 : num_guest;
		create Stage number: num_stage;
		allGuests <- agents of_generic_species Guest;
	}
}


experiment festivalStages type: gui{
	output{
		display Festival{
			species Stage;
			species Guest;
			species Leader;
		}
	}
}