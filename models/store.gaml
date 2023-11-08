/**
* Name: store
* Store species for the homework 
* Author: Andreas Naoum, Soma Seres
*/

model store

import "global_species.gaml"

/**
 * The species representing the stores of the festival.
 * Guests can buy food and drink here to refill their values based on the services the store has to offer.
 */
species Store{
	/**
	 * Flag for representing that the store offers food for the guests.
	 */
	bool hasFood <- flip(0.75);
	
	/**
	 * Flag for representing that the store offers drinks for the guests.
	 */
	bool hasDrink <- flip(0.75);
	
	/**
	 * The graphical representation of the Store species.
	 */
	aspect base {
		//It is a medium sized brown square
		draw square(3.0) color: rgb("brown");
		//If the store does not offer any services, it has an E label on it
		string label <- "E";
		
		if(hasFood and hasDrink){ //If the store offers both food and drinks it has an FD label on it
			label <- "FD";
		} else if(hasFood){ //If the store offers only food it has an F label on it
			label <- "F";
		} else if(hasDrink){ //If the store offers only drinks it has a D label on it
			label <- "D";
		}
		
		draw label size: 3 color: #white anchor: {0.5,0.5} font: font("Helvetica", 12 , #bold);
	}
	
	/**
	 * Action responsible for selling food and/or drinks from the store for the Guest passed as a parameter.
	 */
	action buy(Guest g){
		g <- g.refill(hasFood, hasDrink);
	}
}