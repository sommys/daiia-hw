/**
* Name: stage
* Stage species for the festival project 
* Author: Andreas Naoum, Soma Seres
*/

model stage

import "global_species.gaml"

/**
 * Stage species for the festival project
 */
species Stage skills:[fipa]{
	/**
	 * Values for each attribute of the current concert.
	 */
	map<string, float> attribs <- [];
	/**
	 * Phase of the concert at the stage
	 * 0 = setup
	 * 1 = countdown
	 * 2 = running
	 */
	int phase <- 0;
	int time_counter <- 0 update: time_counter+1;
	
	/**
	 * Randomize attributes for the upcoming concert.
	 */
	action setConcertAttributes{
		loop a over: concert_attribs {
			add rnd(0.5, 1.0) at: a to: attribs; 
		}
	}
	
	/**
	 * Announce the concert to the guests once the setup is over.
	 */
	reflex announceConcert when: phase = 0 and time_counter >= time_setup{
		//Randomize the attributes for the upcoming concert
		do setConcertAttributes;
		//Print the attributes for debugging and logging purposes
		write "Upcoming concert with the following attributes: "+attribs;
		do start_conversation (to: allGuests, protocol: 'fipa-propose', performative: 'propose', contents: [attribs]);
		phase <- 1;
		time_counter <- 0;
	}
	
	/**
	 * Start the concert once the countdown after the announcement is over
	 */
	reflex startConcert when: phase = 1 and time_counter >= time_countdown{
		phase <- 2;
		time_counter <- 0;
	}
	
	/**
	 * End the concert once the concert time is over
	 */
	reflex endConcert when: phase = 2 and time_counter >= time_concert{
		//Inform guests about the end of concert
		do start_conversation (to: allGuests, protocol: 'fipa-propose', performative: 'inform', contents: ['EOC']);
		phase <- 0;
		time_counter <- 0;
	}
	
	/**
	 * The graphical representation of the Stage species.
	 */
	aspect default{
		//The stage is a large lightgray square
		draw square(6) color: #lightgray;
		//If the concert is underway, "lights" are flashing
		if(phase=2){
			draw triangle(2) color: time mod 4 = 0 ? #pink : #yellow at: location + {-2, -2};
			draw triangle(2) color: time mod 4 = 0 ? #yellow : #pink at: location + { 0, -2};
			draw triangle(2) color: time mod 4 = 0 ? #pink : #yellow at: location + { 2, -2};
		}
	}
}