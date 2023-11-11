/**
* Name: informationcenter
* Information Center species for the homework 
* Author: Andreas Naoum, Soma Seres
*/

model informationcenter

import "global_species.gaml"

/**
 * The species representing the information center of the festival.
 * It can tell the visitors the closes store from a given point with the required services (food and/or drink).
 */
species InformationCenter{
	
	list<Guest> bad_guys <- [];
	
	/**
	 * The graphical representation of the InformationCenter species.
	 */
	aspect base {
		//It is a large blue square
		draw square(5.0) color: rgb("blue");
	}
	
	bool is_bad_guy {
		
		float ask_for_different <- rnd(0.0, 10.0);
			
		if (ask_for_different <= 0.5) {
			return true;
		}
		
		return false;
	}
	
	/**
	 * Action responsible for finding the nearest Store from a given point with the required services (food and/or drink).
	 * Checks every store in the festival with the required services and returns the closes one from the point passed as a parameter.
	 */
	Store closest_store_with_supply(Guest guest, point from, bool needFood, bool needDrink){
		
		if (is_bad_guy()){
			add guest to: bad_guys;
			return nil;
		}
		
		Store satisfyingStore <- nil;
		float min_diff <- #max_float;
		
		loop s over: Store{
			bool considerable <- (needFood and needDrink and s.hasFood and s.hasDrink) or (needFood and !needDrink and s.hasFood) or (!needFood and needDrink and s.hasDrink);
			
			if(considerable){
				float distance <- from distance_to s.location;
				if(distance < min_diff){
					min_diff <- distance;
					satisfyingStore <- s;
				}
			}
		}
		
		return satisfyingStore;
	}
	
	Store different_store_with_supply(Guest guest, list<Store> visited, point from, bool needFood, bool needDrink){
		
		if (is_bad_guy()){
			add guest to: bad_guys;
			return nil;
		}
		
		Store satisfyingStore <- nil;
		float min_diff <- #max_float;
		
		bool visited_empty <- empty(visited);
		
		if (visited_empty) {
			return closest_store_with_supply(guest, from, needFood, needDrink);
		}
		
		loop s over: Store{
			bool considerable <- (needFood and needDrink and s.hasFood and s.hasDrink) or (needFood and !needDrink and s.hasFood) or (!needFood and needDrink and s.hasDrink);
			
			if(considerable and !(visited contains s)){
				satisfyingStore <- s;
				break;
			}
		}
		
		if (satisfyingStore=nil){
			return closest_store_with_supply(guest, from, needFood, needDrink);
		}
		
		return satisfyingStore;
	}
	
	Guest ask_for_bad_guy {
		
		if (empty(bad_guys)){
			return nil;
		}
		
		Guest bad_one <- (bad_guys at 0);
		remove from:bad_guys index:0; 
		
		return bad_one;
	}
	
}
