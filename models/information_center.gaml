/**
* Name: informationcenter
* Description: Information Center species for the homework project
* Author: Andreas Naoum, Soma Seres
*/

model informationcenter

import "global_species.gaml"

/**
 * The species representing the information center of the festival.
 * It can tell the visitors the closes store from a given point with the required services (food and/or drink).
 */
species InformationCenter{
	/**
	 * List of bad guys at the festival
	 */
	list<Guest> bad_guys <- [];
	
	/**
	 * The current target for the guards to kill
	 */
	Guest suspect <- nil;
	
	/**
	 * The graphical representation of the InformationCenter species.
	 */
	aspect base {
		//It is a large blue square
		draw square(5.0) color: rgb("blue");
	}
	
	/**
	 * When there are bad guys recorded and no current target is set, report the latest recorded bad guys to the guards
	 */
	reflex reportBadGuy when: (!empty(bad_guys) and suspect = nil){
		//set the target and remove him from the list
		suspect <- bad_guys at 0;
		remove from:bad_guys index:0;
		//report the suspect to the guards
		ask SecurityGuard{
			do reportBadGuest g:myself.suspect;
		}
	}
	
	/**
	 * Action for giving a store for a guest with the requested parameters
	 */
	Store askForStore(Guest guest, bool needFood, bool needDrink){
		//With a low chance, the InformationCenter responds slowly to the Guest, which makes him upset, and triggers its bad behavior
		if (extra_bad_behavior and rnd(0.0, 1.0) <= bad_behavior_threshold){
			//Record the guest as a bad guy and mark it as non-wanted person, and do not give him a store to go to.
			add guest to: bad_guys;
			guest.shallBeRemoved <- true;
			return nil;
		}
		
		//when small memory brain is used and the guest has already visited stores, try to return a different store
		if extra_small_brain and !empty(guest.visited_stores) {
			return differentStore(guest, guest.visited_stores, needFood, needDrink);
		}
		
		return closestStore(guest, needFood, needDrink);
	}
	
	/**
	 * Helper action for deciding if a store shall be considered for the current situation.
	 * needFood and needDrink represent the needs of the Guest (they are hungry and/or thirsty).
	 * visited represents the stores already visited by the agent (if they have a memory, otherwise it is nil).
	 */
	bool isStoreConsiderable(Store s, bool needFood, bool needDrink, list<Store> visited){
		if(visited != nil and visited contains s){ //if we have a visited list and it already contains the current store, try to give a different one
			return false;
		}
		//match the needs of the guest with the services of the store
		return (needFood and needDrink and s.hasFood and s.hasDrink) or (needFood and !needDrink and s.hasFood) or (!needFood and needDrink and s.hasDrink);
	}
	
	/**
	 * Action responsible for finding the nearest Store from the Guest's location with the required services (food and/or drink).
	 * Checks every store in the festival with the required services and returns the closest one from the Guest passed as a parameter.
	 */
	Store closestStore(Guest guest, bool needFood, bool needDrink){
		Store satisfyingStore <- nil;
		float min_diff <- #max_float;
		loop s over: Store{
			//if the store has what the guest needs
			if(isStoreConsiderable(s, needFood, needDrink, nil)){
				//search for the minimum distance
				float distance <- guest.location distance_to s.location;
				if(distance < min_diff){
					min_diff <- distance;
					satisfyingStore <- s;
				}
			}
		}
		return satisfyingStore;
	}
	
	/**
	 * Action responsible for finding a store for the Guest in the guest parameter, which is not in the visited list.
	 * Checks every store in the festival with the required services and returns the first one that is not in the visited list.
	 * If all stores are in the visited list, the action falls back to using the closest store from the Guest.
	 */
	Store differentStore(Guest guest, list<Store> visited, bool needFood, bool needDrink){
		loop s over: Store{
			if(isStoreConsiderable(s, needFood, needDrink, visited)){
				return s;
			}
		}
		return closestStore(guest, needFood, needDrink);
	}
}
