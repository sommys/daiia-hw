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
	map<string, float> attribs <- [];
	
	//0 = setup
	//1 = countdown
	//2 = running
	int phase <- 0;
	int time_counter <- 0;
	
	init{
		loop a over: concert_attribs{
			add 0.0 at: a to: attribs;
		}
	}
	
	action setConcertAttributes{
		loop a over: concert_attribs{
			add rnd(0.1, 5.0) at: a to: attribs; 
		}
	}
	
	reflex increaseTimeCounter{
		time_counter <- time_counter+1;
	}
	
	reflex announceConcert when: phase = 0 and time_counter >= time_setup{
		//concert setup is done, we can announce it to the public with the attributes
		do setConcertAttributes;
		write "Upcoming convert with the following attributes: "+attribs;
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'propose', contents: [attribs]);
		phase <- 1;
		time_counter <- 0;
	}
	
	reflex startConcert when: phase = 1 and time_counter >= time_countdown{
		phase <- 2;
		time_counter <- 0;
	}
	
	reflex endConcert when: phase = 2 and time_counter >= time_concert{
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'inform', contents: ['EOC']);
		phase <- 0;
		time_counter <- 0;
	}
	
	aspect default{
		draw square(6) color: #lightgray;
		if(phase=2){
			draw triangle(2) color: time mod 4 = 0 ? #pink : #yellow at: location + {-2, -2};
			draw triangle(2) color: time mod 4 = 0 ? #yellow : #pink at: location + { 0, -2};
			draw triangle(2) color: time mod 4 = 0 ? #pink : #yellow at: location + { 2, -2};
		}
	}
}