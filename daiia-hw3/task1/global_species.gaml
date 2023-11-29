/**
* Name: global_species
* Global species for the NxN queen problem 
* Author: Andreas Naoum, Soma Seres
*/

model global_species

import "chess_board.gaml"
import "queen.gaml"

/**
 * Global species for the NxN queen problem
 * FIPA skill for starting the first queen to find its place
 */
global skills:[fipa]{
	/**
	 * Number of queens and size of the table
	 */
	int N <- 6;
	/**
	 * Flag for stopping the simulation once a solution is found
	 */
	bool done <- false;
	
	init{
		/**
		 * Create N queens with the given ids
		 */
		loop i from: 0 to: N-1 {
        	create Queen{
        		do setId _id: i;
        	}
        }
        /**
         * Start the problem solving by sending the 'find' message to the first queen
         */
        do start_conversation with:(to: list(Queen[0]), protocol: 'fipa-propose', performative: 'inform', contents: ['find', []]);
	}
	
	/**
	 * Stop the simulation once the done flag is set to true (solution is found)
	 */
	reflex stop when: done{
		write "Done!";
		do pause;
	}
}

experiment NQueensProblem type: gui{
	output{
		display ChessBoard{
			grid ChessBoard border: #black;
			species Queen;
		}
	}
}