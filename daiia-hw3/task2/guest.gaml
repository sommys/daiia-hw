/**
* Name: guest
* Guest species for the festival project 
* Author: Andreas Naoum, Soma Seres
*/

model guest

import "global_species.gaml"

/**
 * Regular Guests at the festival going to concerts based on different preferences.
 */
species Guest skills:[moving, fipa]{
	/**
	 * The current stage with the guest's preferred concert.
	 */
	Stage preferredStage <- nil;
	/**
	 * Flag to indicate if the guest can start moving towards the stage.
	 */
	bool canGo <- false;
	/**
	 * Weights for each attribute of a concert representing the preferences of the guest.
	 */
	map<string, float> weights <- [];
	
	/**
	 * Flag if guest does not like crowd.
	 */
	bool do_not_prefer_crowd <- flip(0.1);
	/**
	 * Flag to indicate if they take a decision for which act they want to go.
	 */
	bool decision_taken <- false;
	/**
	 * Map for keeping the calculated utilities in case a rearrangment is needed to maximize global utility.
	 */
	map<Stage, float> utilities <- [];
	
	init{
		loop a over: concert_attribs {
			add rnd(0.5, 1.5) at: a to: weights; //Randomize values for each attribute's weight for the preferences
		}
		write name + ": My preferences (weights): " + weights; //Print preferences for debugging and logging purposes
	}
	
	/**
	 * Handle the received final stage from the leader if crowd_mass preference is enabled
	 */
	reflex receiveFinalAct when: crowd_mass_enabled and !canGo and !empty(informs){
		loop msg over: informs {
			string command <- msg.contents[0];
			//If the leader sent the 'Final' command
			if(command = "Final"){
				//Check if the final Stage changed from the original preference
				Stage finalStage <- msg.contents[1];
				if(preferredStage != finalStage){
					//Print change of stage for debugging and logging purposes
					write name + ": I m changing act from " + preferredStage + " to " + finalStage;
					//Change the preferredStage variable as well
					preferredStage <- finalStage;
				}
			}
		}
		//We can finally go to the concert
		canGo <- true;
	}
	
	/**
	 * Whenever the guest is at the party or there is no current concert underway, it moves around
	 */
	reflex partyOrRest when: canGo or preferredStage = nil {
		do wander;
	}
	
	/**
	 * Whenever the guest should be at their preferred stage but they are out of range, they move towards the stage
	 */
	reflex goToStage when: canGo and preferredStage != nil and location distance_to(preferredStage) > concert_distance_threshold{
		do goto target: preferredStage.location;
	}
	
	/**
	 * Helper action for calculating utility for a given set of attribute values of a concert
	 */
	float utility(map<string, float> infos){
		float util <- 0.0;
		loop a over: concert_attribs{
			util <- util + weights[a] * infos[a];
		}
		return util;
	}
	
	/**
	 * Helper action for resetting variables at the end of a concert
	 */
	action endOfConcertReset{
		preferredStage <- nil;
		canGo <- false;
		decision_taken <- false;
		utilities <- [];
	}
	
	/**
	 * Handle the end of concert messages from stages
	 */
	reflex handleEndOfConcert when: canGo and !empty(informs){
		loop endInfo over: informs{
			//Check if the received message is from the preferred stage and it is an end-of-concert announcement
			if(endInfo.sender = preferredStage and endInfo.contents[0] = 'EOC'){
				//Reset variables
				do endOfConcertReset;
			}
			do end_conversation message:endInfo contents: ['OK'];
		}
	}
	
	/**
	 * Helper action for processing the received list of concerts
	 */
	action processUtilities(list<message> stageInfoMessages){
		float highestUtility <- 0.0;
		loop stageInfoMsg over: stageInfoMessages {
			//get the attributes and calculate utility
			map<string, float> stageInfo <- stageInfoMsg.contents[0];
			float utility <- utility(stageInfo);
			//store utility for further tasks
			utilities[stageInfoMsg.sender] <- utility;
			//change preference if the current one is higher
			if(utility > highestUtility){
				highestUtility <- utility;
				preferredStage <- stageInfoMsg.sender;
			}
		}
		//If crowd_mass is enabled, we only decided ourselves, but need to tell our values to the leader and wait for final decision
		if (crowd_mass_enabled){
			decision_taken <- true;
			write name + ": I decided to go to " + preferredStage + " (utility: " + highestUtility + ")";
			do start_conversation (to: list(Leader), protocol: 'fipa-propose', performative: 'inform', contents: [preferredStage, utilities, do_not_prefer_crowd]);
		//Otherwise our decision is final and we can go to the concert
		} else {
			canGo <- true;
			write name + ": I'm going to " + preferredStage + " (utility: " + utilities[preferredStage] + ")";
		}
	}
	
	/**
	 * Handle concert informations received from stages
	 */
	reflex handleStageInfos when: !decision_taken and !empty(proposes){
		do processUtilities stageInfoMessages: proposes;
	}
	
	/**
	 * The graphical representation of the Guest species.
	 */
	aspect default{
		//The representation is a small circle
		draw circle(1) color: #green;
		//When the concert is underway, the lights are flashing on the guests
		if(preferredStage != nil and preferredStage.phase = 2 and location distance_to(preferredStage) <= concert_distance_threshold and time mod 2 = 0){
			draw circle(0.5) color: one_of([#lightgreen, #pink, #yellow, #orange, #lightblue]);
		}
	}
}