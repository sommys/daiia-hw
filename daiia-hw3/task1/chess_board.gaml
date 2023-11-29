/**
* Name: chess_board
* ChessBoard species for the NxN queen problem
* Author: Andreas Naoum, Soma Seres
*/

model chess_board

import "global_species.gaml"
/**
 * Grid species for representing the chess board for the NxN queen problem
 * Width and Height are both N (as we need an NxN table)
 */
grid ChessBoard width:N height:N{
	/**
	 * Flag for stating the occupancy of this cell
	 */
	bool occupied <- false;
	init{
		//coloring in black-white
		if((even(grid_x) and even(grid_y)) or (!even(grid_x) and !even(grid_y))){
			color <- #black;
		}
		else {
			color <- #white;
		}
	}
}