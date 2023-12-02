/**
* Name: guest
* Guest species for the festival project 
* Author: Andreas Naoum, Soma Seres
*/

model guest

import "global_species.gaml"

species Guest skills:[moving, fipa]{
	
	
	Stage preferredStage <- nil;
	bool canGo <- false;
	map<string, float> weights <- [];
	
	
	
	// -------- Variables for Challenge --------
	
	// 10% changes to not want crowd
	float rnd_want_crowd <- rnd(0.0, 1.0);
	
	// Flag if guest does not like crowd
	bool do_not_prefer_crowd <- false ;
	
	// Flag to indetify the leader
	bool leader_flag <- false;
	
	// When all guests informed leader, the leader can then decide where they should go
	bool leader_must_decide <- false;
	
	// Flag to indicate if they take a decision for which act they want to go
	bool decision_taken <- false;
	
	// Flag to indicate that guest informed leader
	bool inform_leader <- false;
	
	// Counter for received information
	int guests_informs_count <- 0;
	
	float global_utility_before <- 0.0;
	float global_utility_after <- 0.0;
	list<Guest> guests <- [];
	map<Stage, float> utilities <- [];
	map<Stage, int> crowd <- [];
	map<Guest, Stage> guests_preferred_stages <- [];
	map<Guest, bool> guests_not_crowd <- [];
	map<pair<Guest, Stage>, float> guests_utilities <- [];
	
	
	map<Guest, Stage> new_preferred_stages <- [];
	
	matrix guests_utilities_matrix <- [];
	
	init{
		loop a over: concert_attribs {
			add rnd(0.5, 1.5) at: a to: weights;
		}
		
		if (crowd_mass_enabled) {
			if (rnd_want_crowd < 0.1){
				do_not_prefer_crowd <- true;
			}
			
			if (name = "Guest0"){
				leader_flag <- true;
				write name + " I am the leader!!!";
			} 
		}
		write name + ": My preferences (weights): " + weights;
	}
	
	
	reflex informLeader when: crowd_mass_enabled and !leader_flag and !inform_leader and decision_taken and preferredStage != nil {
		do start_conversation (to: list(leader), protocol: 'fipa-propose', performative: 'inform', contents: [preferredStage, utilities, do_not_prefer_crowd]);
		inform_leader <- true;
	}
	
	
	reflex receiveNewActs when: crowd_mass_enabled and !canGo and !leader_flag and inform_leader and !empty(informs){
		
		loop msg over: informs {
			map<Guest, Stage> new_acts <- msg.contents[0];
			if (new_acts[self] != nil) {
				write name + " I m changing act before " + preferredStage + " after: " + new_acts[self];
				preferredStage <- new_acts[self];
			}
		}
		
		canGo <- true;
	}
	
	reflex decideActs when: crowd_mass_enabled and leader_flag and !canGo and leader_must_decide {
		
		// Calculate the Global Utility before changes
		// We add by 1 if the guest does like crowd and there is crowd in the act 
		// We add by 1 if the guest does not like crowd and there is no crowd in the act 
		loop g over: guests {
			Stage preffered <- guests_preferred_stages[g];
			if (guests_not_crowd[g] and crowd[preffered] <= 2) {
				global_utility_before <- global_utility_before + guests_utilities[g::preffered] + 1.0;
			} 
			else if (guests_not_crowd[g]=false and crowd[preffered] > 2) {
				global_utility_before <- global_utility_before + guests_utilities[g::preffered] + 1.0;
			}
			else {
				global_utility_before <- global_utility_before + guests_utilities[g::preffered];
			}
		}
		
		// find new acts for the anti-social guests
		loop g over: guests {
			Stage preffered <- guests_preferred_stages[g];
			if (guests_not_crowd[g] and crowd[preffered] > 1) {
				Stage new_preffered <- nil;
				float highestUtility <- 0.0;
				loop s over: list(Stage) {
					if(crowd[s] <= 1 and guests_utilities[g::s] > highestUtility){
						highestUtility <- guests_utilities[g::s];
						new_preffered <- s;
					}
				}
				if (new_preffered != nil){
					crowd[preffered] <- crowd[preffered] - 1;
					new_preferred_stages[g] <- new_preffered;
					guests_preferred_stages[g] <- new_preffered;
					crowd[new_preffered] <- crowd[new_preffered] + 1;
				} 
			}
		}
		
		// special case when only two guests are in an act, one anti-social and one social
		// social one is sacrificing
		loop key over: keys(crowd) {
			
			if (crowd[key]=2) {
				bool special_case_not_crowd <- false;
				bool special_case_crowd <- false;
				
				loop g over: guests {
					if (guests_preferred_stages[g] = key and guests_not_crowd[g]) {
						special_case_not_crowd <- true;
					} 
					else if (guests_preferred_stages[g] = key and guests_not_crowd[g]=false){
						special_case_crowd <- true;
					}
				}
				
				if (special_case_not_crowd and special_case_crowd){
					loop g over: guests {
						if (guests_preferred_stages[g] = key and guests_not_crowd[g]=false){
							Stage new_preffered <- nil;
							float highestUtility <- 0.0;
							loop s over: list(Stage) {
								if(crowd[s] > 1 and guests_utilities[g::s] > highestUtility){
									highestUtility <- guests_utilities[g::s];
									new_preffered <- s;
								}
							}
							if (new_preffered != nil){
								crowd[key] <- crowd[key] - 1;
								new_preferred_stages[g] <- new_preffered;
								guests_preferred_stages[g] <- new_preffered;
								crowd[new_preffered] <- crowd[new_preffered] + 1;
								write "This guest is sacrificing for the common good -> " + g + " before: " + key + " , after: "+ new_preffered;
							} 
						}
					}
				}
				
			}
		}
		
		// Calculate the Global Utility after changes
		// We add by 1 if the guest does like crowd and there is crowd in the act 
		// We add by 1 if the guest does not like crowd and there is no crowd in the act 
		loop g over: guests {
			Stage preffered <- guests_preferred_stages[g];
			if (guests_not_crowd[g] and crowd[preffered] <= 2) {
				global_utility_after <- global_utility_after + guests_utilities[g::preffered] + 1.0;
			} 
			else if (guests_not_crowd[g]=false and crowd[preffered] > 2) {
				global_utility_after <- global_utility_after + guests_utilities[g::preffered] + 1.0;
			}
			else {
				global_utility_after <- global_utility_after + guests_utilities[g::preffered];
			}
		}
		
		write "Leader: new preffered stages -> " + new_preferred_stages;
		loop key over: keys(crowd) {
			write "Leader: Population at stage " + key + ": " + crowd[key];
		}
		write "Global Utilities -> Before: " + int(global_utility_before) + " After: " + int(global_utility_after);
		do start_conversation(to: list(Guest), protocol: 'fipa-propose', performative: 'inform', contents: [new_preferred_stages]);
		canGo <- true;
		leader_must_decide <- false;
		
	}
	
	reflex guestsInforms when: crowd_mass_enabled and leader_flag and !canGo and !empty(informs){
		loop msg over: informs {
			add msg.sender to: guests;
			guests_informs_count <- guests_informs_count + 1;
			Stage guest_preferred_stage <- msg.contents[0];
			crowd[guest_preferred_stage] <- crowd[guest_preferred_stage] + 1;
			guests_preferred_stages[msg.sender] <- guest_preferred_stage;
			guests_not_crowd[msg.sender] <- bool(msg.contents[2]);
			do end_conversation message:msg contents: ['OK'];
			map<Stage, float> guest_utilities <-  msg.contents[1];
			loop key over: keys(guest_utilities) {
				guests_utilities[msg.sender::key] <- guest_utilities[key];
			}
		}

		if (guests_informs_count=num_guest-1) {
			write "Leader: All guests informed me!";
			leader_must_decide <- true;
		}
		
	}
	
	// !canGo
	reflex nothingToDo when: canGo or preferredStage = nil {
		do wander;
	}
	
	reflex goToStage when: canGo and preferredStage != nil and location distance_to(preferredStage) > concert_distance_threshold{
		do goto target: preferredStage.location;
	}
	
	float utility(map<string, float> infos){
		float util <- 0.0;
		loop a over: concert_attribs{
			util <- util + weights[a] * infos[a];
		}
		return util;
	}
	
	reflex handleEndOfConcert when: canGo and !empty(informs){
		loop endInfo over: informs{
			if(endInfo.sender = preferredStage and endInfo.contents[0] = 'EOC'){
				preferredStage <- nil;
				canGo <- false;
				inform_leader <- false;
				decision_taken <- false;
				utilities <- [];
				if (leader_flag) {
					guests_informs_count <- 0;
					global_utility_before <- 0.0;
					global_utility_after <- 0.0;
					guests <- [];
					utilities <- [];
					guests_preferred_stages <- [];
					crowd <- [];
					guests_utilities <- [];
					guests_not_crowd <- [];
				}
			}
			do end_conversation message:endInfo contents: ['OK'];
		}
	}
	
	reflex handleStageInfos when: !decision_taken and !empty(proposes){
		float highestUtility <- 0.0;
		loop stageInfoMsg over: proposes {
			map<string, float> stageInfo <- stageInfoMsg.contents[0];
			float utility <- utility(stageInfo);
			utilities[stageInfoMsg.sender] <- utility;
			if(utility > highestUtility){
				highestUtility <- utility;
				preferredStage <- stageInfoMsg.sender;
			}
		}
		
		if (crowd_mass_enabled){
			decision_taken <- true;
			write name + ": I decided to go to " + preferredStage + " (utility: " + highestUtility + ")";
			
			if (leader_flag){
				crowd[preferredStage] <- crowd[preferredStage] + 1;
			}
		} else {
			canGo <- true;
			write name + ": I'm going to " + preferredStage + " (utility: " + highestUtility + ")";
		}
	}
	
	/**
	 * The graphical representation of the Guest species.
	 */
	aspect default{
		//The representation is a small circle
		draw circle(1) color: #green;
		if(preferredStage != nil and preferredStage.phase = 2 and location distance_to(preferredStage) <= concert_distance_threshold and time mod 2 = 0){
			draw circle(0.5) color: one_of([#lightgreen, #pink, #yellow, #orange, #lightblue]);
		}
	}
}