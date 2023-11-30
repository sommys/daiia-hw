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
	
	init{
		loop a over: concert_attribs{
			add rnd(0.5, 1.5) at: a to: weights;
		}
		write name + ": My preferences (weights): " + weights;
	}
	
	reflex nothingToDo when: !canGo or preferredStage = nil{
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
	
	reflex handleEndOfConcert when: !empty(informs){
		loop endInfo over: informs{
			if(endInfo.sender = preferredStage and endInfo.contents[0] = 'EOC'){
				preferredStage <- nil;
				canGo <- false;
			}
			do end_conversation message:endInfo contents: ['OK'];
		}
	}
	
	reflex handleStageInfos when: !empty(proposes){
		float highestUtility <- 0.0;
		loop stageInfoMsg over: proposes{
			map<string, float> stageInfo <- stageInfoMsg.contents[0];
			float utility <- utility(stageInfo);
			if(utility > highestUtility){
				highestUtility <- utility;
				preferredStage <- stageInfoMsg.sender;
			}
		}
		canGo <- true;
		write name + ": I'm going to " + preferredStage + "(utility: " + highestUtility + ")";
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