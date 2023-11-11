/**
* Name: securityguard
* Description: SecurityGuard species for the homework project
* Author: Andreas Naoum, Soma Seres
*/

model securityguard

import "global_species.gaml"

/**
 * The species representing the guards of the festival.
 * It can handle reports of bad guys, and then go to the InformationCenter for further info, then kill the bad guys.
 */
species SecurityGuard skills: [moving]{	
	Guest bad <- nil;
	bool report <- false;
	
	init{
		speed <- 3.0; //Make the guards faster, so they can catch the bad behaving guests
	}
	
	/**
	 * The graphical representation of the SecurityGuard species.
	 */
	aspect base {
		//Guards are represented with a medium sized black filled circle
		draw circle(2) color: rgb("black");
	}
	
	/**
	 * When there is no report, the guard wanders around the festival, keeping an open eye.
	 */
	reflex allGood when: (!report){
		do wander;
	}
	
	/**
	 * When the Information Center reported a bad guy, the guard goes to there, to pickup further information about the suspect.
	 */
	reflex goToInfoCenter when: (report and self distance_to infocenter_location >= distance_threshold){
		do goto target: infocenter_location;	
	}
	
	/**
	 * When the Information Center reported a bad guy, and the guard is there, he gets further information about the suspect, and sets him as a target.
	 */
	reflex atInfoCenter when: (report and self distance_to infocenter_location < distance_threshold and bad = nil){
		ask InformationCenter{
			myself.bad <- self.suspect;
		}
	}
	
	/**
	 * When there is a reported bad guy and the guard knows their description, the guard goes to the target's location
	 */
	reflex goToSuspect when: (report and bad != nil and self distance_to bad >= distance_threshold){
		do goto target: bad;
	}
	
	/**
	 * When the guard reaches the reported suspect, he kills it and tells the InformationCenter on radio, that the suspect is eliminated. 
	 */
	reflex killSuspect when: (report and bad != nil and self distance_to bad < distance_threshold){
		bad <- bad.removeFromFestival();
		bad <- nil;
		report <- false;
		ask InformationCenter{
			self.suspect <- nil;
		}
	}
	
	/**
	 * Action for reporting a Guest with bad behavior passed as a parameter.
	 */
	action reportBadGuest(Guest g){
		bad <- g;
		report <- true;
	}
}