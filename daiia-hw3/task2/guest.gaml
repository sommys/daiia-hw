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
	
	float rnd_want_crowd <- rnd(0.0, 1.0);
	
	bool leader_flag <- false;
	
	bool decision_taken <- false;
	bool inform_leader <- false;
	
	bool ask_him_to_leave <- false;
	int proposed_times <- 0;
	Stage before <- nil;
	float before_value <- 0.0;
	
	int guests_informs_count <- 0;
	
	map<string, float> weights <- [];
	
	map<Stage, float> utilities <- [];
	map<Stage, int> crowd <- [];
	
	
	
	init{
		loop a over: concert_attribs {
			add rnd(0.5, 1.5) at: a to: weights;
		}
		if (name = "Guest0"){
			leader_flag <- true;
			write name + " I am the leader!!!";
		} 
		write name + ": My preferences (weights): " + weights;
	}
	
	reflex goToLeader when: !leader_flag and !canGo and decision_taken and location distance_to(leader.location) > leader_distance_threshold{
		do goto target: leader.location;
	}
	
	reflex goToMeetingPoint when: leader_flag and !canGo and location distance_to({0,0}) > 0 {
		do goto target: {0, 0};
	}
	
	reflex informLeader when: !leader_flag and !inform_leader and decision_taken and preferredStage != nil and location distance_to(leader.location) < leader_distance_threshold {
		// write "I am informing the leader " + leader + ", guest " + self;
		do start_conversation (to: list(leader), protocol: 'fipa-propose', performative: 'inform', contents: [preferredStage]);
		inform_leader <- true;
	}
	
	reflex receivePopulations when: !canGo and !leader_flag and inform_leader and !empty(informs){
		
		map<Stage, int> map_crowd <- nil;
		loop msg over: informs {
			map_crowd <- msg.contents[0];
			do end_conversation message:msg contents: ['OK'];
		}
		
		loop key over: keys(utilities) {

			if (rnd_want_crowd < 0.1)  {
				if map_crowd[key] <= 1 {
					utilities[key] <- utilities[key] + rnd(2.0, 6.0);
				} else {
					utilities[key] <- utilities[key] - 4.0;
				}
			}
		}
		
		global_utility_before <- global_utility_before + utilities[preferredStage];
		
		float highest_before <- utilities[preferredStage];
		Stage stage_before <- preferredStage;
		
		float highestUtility <- 0.0;
		loop key over: keys(utilities) {
			if(utilities[key] > highestUtility){
				highestUtility <- utilities[key];
				preferredStage <- key;
			}
		}
		
		float highest_after <- utilities[preferredStage];
		
		if highest_before!=highest_after {
			write name + " I decided to go to " + preferredStage + "over " + stage_before + " because i don't like the crowd";
		}
		
		if (rnd_want_crowd < 0.2 and map_crowd[preferredStage] = 1 )  {
			write name + " Ask other guest to change act";
			ask_him_to_leave <- true;
			do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'propose', contents: [preferredStage]);
		}
		
		global_utility_after <- global_utility_after + utilities[preferredStage];
		
		canGo <- true;
	}
	
	reflex guestsInforms when: leader_flag and !canGo and !empty(informs){
		loop msg over: informs {
			guests_informs_count <- guests_informs_count + 1;
			Stage guest_preferred_stage <- msg.contents[0];
			crowd[guest_preferred_stage] <- crowd[guest_preferred_stage] + 1;
			do end_conversation message:msg contents: ['OK'];
		}
		
		if (guests_informs_count=num_guest-1) {
			write "Leader: All guests informed me!";
			loop key over: keys(crowd) {
				write "Leader: Population at stage " + key + ": " + crowd[key];
			}
			do start_conversation(to: list(Guest), protocol: 'fipa-propose', performative: 'inform', contents: [crowd]);
			canGo <- true;
		}
		
	}
	
	reflex changeAct when: decision_taken and !empty(proposes){
		message msg <- proposes at 0;
		if(msg.contents[0] = preferredStage) {
			proposed_times <- proposed_times + 1;
			if proposed_times > 1 {
				write name + " Nevermind, a received another proposed to leave";
				global_utility_after <- global_utility_after - utilities[preferredStage];
				global_utility_after <- global_utility_after + before_value;
				preferredStage <- before;
			}
		}
		if(msg.contents[0] = preferredStage and length(proposes)=1 and !ask_him_to_leave ){
			before <- preferredStage;
			before_value <- utilities[preferredStage];
			global_utility_after <- global_utility_after - utilities[preferredStage];
			utilities[preferredStage] <- 0;
			float highestUtility <- 0.0;
			loop key over: keys(utilities) {
				if(utilities[key] > highestUtility){
					highestUtility <- utilities[key];
					preferredStage <- key;
				}
			}
			Stage after <- preferredStage;
			write name + " I m changing act for the common good, before: " + before + " after: " + after;
			global_utility_after <- global_utility_after + utilities[preferredStage];
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
				ask_him_to_leave <- false;
				crowd <- [];
				utilities <- [];
				proposed_times <- 0;
				before <- nil;
				if (leader_flag) {
					guests_informs_count <- 0;
					write "Global Utilities -> Before: " + int(global_utility_before) + " After: " + int(global_utility_after);
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