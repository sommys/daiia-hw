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
	/**
	 * The graphical representation of the InformationCenter species.
	 */
	aspect base {
		//It is a large blue square
		draw square(5.0) color: rgb("blue");
	}
	
	/**
	 * Action responsible for finding the nearest Store from a given point with the required services (food and/or drink).
	 * Checks every store in the festival with the required services and returns the closes one from the point passed as a parameter.
	 */
	Store closest_store_with_supply(point from, bool needFood, bool needDrink){
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
}
