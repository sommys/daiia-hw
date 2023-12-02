/**
* Name: leader
* Leader species for the festival project 
* Author: Andreas Naoum, Soma Seres
*/

model leader

import "global_species.gaml"

/**
 * Leader species for coordinating guests at the festival to maximize global utility.
 */
species Leader parent: Guest{
	/**
	 * List of guests that informed the leader about their preferences.
	 */
	list<Guest> guests <- [];
	/**
	 * Crowd at the different stages based on the guest preferences.
	 */
	map<Stage, int> crowd <- [];
	/**
	 * Guests and their preferred stages.
	 */
	map<Guest, Stage> guests_preferred_stages <- [];
	/**
	 * Guests and if they are antisocial or not.
	 */
	map<Guest, bool> guests_not_crowd <- [];
	/**
	 * Exact values for Guest-Stage utility pairs
	 */
	map<pair<Guest, Stage>, float> guests_utilities <- [];
	
	//Override guest reflexes for leader interaction to do nothing for the leaders
	reflex informLeader{}
	reflex receiveNewActs{}
	
	/**
	 * Override end of concert handling, as the leader has further variables to reset
	 */
	action endOfConcertReset{
		invoke endOfConcertReset();
		guests <- [];
		utilities <- [];
		guests_preferred_stages <- [];
		crowd <- [];
		guests_utilities <- [];
		guests_not_crowd <- [];
	}
	
	/**
	 * Helper action for calculating global utility for the current setup
	 */
	float calculateCurrentGlobalUtility{
		float global_utility <- 0.0;
		loop g over: guests {
			Stage preffered <- guests_preferred_stages[g];
			global_utility <- global_utility + guests_utilities[g::preffered];
			if ((guests_not_crowd[g] and crowd[preffered] <= 2) or (!guests_not_crowd[g] and crowd[preffered] > 2)) {
				global_utility <- global_utility + 1.0;
			}
		}
		return global_utility;
	}
	
	/**
	 * Helper action for finding new stage for antisocial guests.
	 * Returns the changes of stages (Guest-new Stage mapping)
	 */
	map<Guest, Stage> findNewStageForAntisocials{
		map<Guest, Stage> changes <- [];
		loop g over: guests {
			Stage preffered <- guests_preferred_stages[g];
			if (guests_not_crowd[g] and crowd[preffered] > 2) {
				Stage new_preferred <- nil;
				float highestUtility <- 0.0;
				loop s over: list(Stage) {
					if(crowd[s] <= 1 and guests_utilities[g::s] > highestUtility){
						highestUtility <- guests_utilities[g::s];
						new_preferred <- s;
					}
				}
				if (new_preferred != nil){
					crowd[preffered] <- crowd[preffered] - 1;
					guests_preferred_stages[g] <- new_preferred;
					crowd[new_preferred] <- crowd[new_preferred] + 1;
					changes[g] <- new_preferred;
				} 
			}
		}
		return changes;
	}
	
	/**
	 * Helper action for handling special case of 2 agents at a stage: a social and an antisocial one.
	 * The social agent sacrifices its preference and leaves the antisocial alone.
	 * The previously made changes are passed as a parameter and the final changes are returned.
	 */
	map<Guest, Stage> handleSpecialCase(map<Guest, Stage> changes){
		//Iterate over the crowds
		loop key over: keys(crowd) {
			//Only care about cases when the crowd is 2
			if (crowd[key]!=2) {
				continue;
			}
			//flag for finding social and antisocial guests
			bool special_case_not_crowd <- false;
			bool special_case_crowd <- false;
			//variable for the social guest as it will sacrifice
			Guest social <- nil;
			//loop over guests to find the ones at the stage
			loop g over: guests {
				//if the preffered stage is the currend one ant the guest is antisocial, we found an antisocial at the stage
				if (guests_preferred_stages[g] = key and guests_not_crowd[g]) {
					special_case_not_crowd <- true;
				}
				//if the preffered stage is the currend one ant the guest is social, we found a social at the stage
				else if (guests_preferred_stages[g] = key and !guests_not_crowd[g]){
					special_case_crowd <- true;
					social <- g;
				}
			}
			
			// if there is both a social and an antisocial at the stage, handle the special case
			if (special_case_not_crowd and special_case_crowd){
				//find new stage for the social guest
				Stage new_preferred <- nil;
				float highestUtility <- 0.0;
				//find the stage with over 2 crowd and highest utility
				loop s over: list(Stage) {
					if(crowd[s] > 2 and guests_utilities[social::s] > highestUtility){
						highestUtility <- guests_utilities[social::s];
						new_preferred <- s;
					}
				}
				//handle change of preference if we could find a new stage
				if (new_preferred != nil){
					crowd[key] <- crowd[key] - 1;
					crowd[new_preferred] <- crowd[new_preferred] + 1;
					guests_preferred_stages[social] <- new_preferred;
					changes[social] <- new_preferred;
					write "This guest is sacrificing for the common good -> " + social + " before: " + key + ", after: "+ new_preferred;
				}
			}
		}
		return changes;
	}
	
	/**
	 * Helper action for deciding the final stages for each guest.
	 */
	action decideActs{
		// Calculate the Global Utility before changes
		float global_utility_before <- calculateCurrentGlobalUtility();
		
		// Find new acts for the anti-social guests
		map<Guest, Stage> changes <- findNewStageForAntisocials();
		
		// Special case when only two guests are in an act, one anti-social and one social
		changes <- handleSpecialCase(changes);
		
		// Calculate the Global Utility after changes
		float global_utility_after <- calculateCurrentGlobalUtility();
		// Print changes made for debugging and logging purposes
		if(length(changes) != 0){
			write name + ": change of final stages: " + changes;
		}
		// Print crowds at stages for debugging and logging purposes
		loop key over: keys(crowd) {
			write name + ": Population at stage " + key + ": " + crowd[key];
		}
		// Print global utility change for debugging and logging purposes
		write name + ": Global Utility -> " + global_utility_before with_precision 2 + " [Before] vs." + global_utility_after with_precision 2 + " [After]";
		// Send out the final stages for each guest
		loop g over:list(Guest){
			do start_conversation(to: list(g), protocol: 'fipa-propose', performative: 'inform', contents: ["Final", guests_preferred_stages[g]]);			
		}
		// Finally, we can go to the concert
		canGo <- true;
	}
	
	/**
	 * Handle guest informations about their preferred stage, antisociality and utilities for each stage
	 */
	reflex guestsInforms when: !canGo and !empty(informs){
		loop msg over: informs {
			//Add the guest to the processed guests list
			add msg.sender to: guests;
			//Add 1 to the crowd of the preferred stage of this guest
			Stage guest_preferred_stage <- msg.contents[0];
			crowd[guest_preferred_stage] <- crowd[guest_preferred_stage] + 1;
			//Save informations for further processing
			guests_preferred_stages[msg.sender] <- guest_preferred_stage;
			guests_not_crowd[msg.sender] <- bool(msg.contents[2]);
			map<Stage, float> guest_utilities <-  msg.contents[1];
			loop key over: keys(guest_utilities) {
				guests_utilities[msg.sender::key] <- guest_utilities[key];
			}
			//End conversation to only process info once
			do end_conversation message:msg contents: ['OK'];
		}
		//If all guests have sent their informations, try to maximize global utility
		if (length(guests)=num_guest) {
			write name + ": All guests informed me!";
			do decideActs;
		}
	}
}
