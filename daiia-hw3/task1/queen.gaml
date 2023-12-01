/**
* Name: queen
* The queen species for the NxN queen problem 
* Author: Andreas Naoum, Soma Seres
*/

model queen

import "global_species.gaml"

/**
 * Queen species for placing on the chessboard with FIPA skill to communicate with adjacent queens
 */
species Queen skills:[fipa]{
	/**
	 * Column of the queen on the board
	 */
	int col;
	/**
	 * Row of the queen on the board (-1 if it is not currently on the board)
	 */
	int row <- -1;
	/**
	 * List of row-column pairs taken on the board by previous queens
	 */
	list<pair<int,int>> taken <- [];
	
	init{
		location <- {-10, -10}; //init them off-the board
	}
	
	/**
	 * Handle incoming inform messages
	 */
	reflex handleTask when: !empty(informs) {
		//take the latest message
		message msg <- informs at 0;
		//the task in in the first position of the contents
		string task <- msg.contents[0];
		//Print the contents for debugging and logging
		write "" + col + ": " + msg.contents;
		//If we need to find a new place for the current queen
		if(task = 'find'){
			//get the occupancy of the board from the message
			list<pair<int, int>> t <- msg.contents[1];
			taken <- t;
			//find a safe row to place the current queen
			do findSafeRow;
		//If we need to rearrange: take the queen of the board and find a next possible safe row
		} else if (task='rearrange'){
			do removeFromBoard;
			do findSafeRow;
		}
		//Empty the informs list, so there is no bugs related to stuck messages
		informs <- nil;
	}
	
	/**
	 * Helper action for removing the queen from the board
	 */
	action removeFromBoard{
		//remove current (last for its list) queens occupancy from the board in the taken list
		remove from:taken index:length(taken)-1;
		//take it off the grid based on location as well
		location <- {-10,-10};
	}
	
	/**
	 * Helper action for finding a safe row and handling the result
	 */
	action findSafeRow{
		//get the first safe cell in the queen's column
		int safeRow <- firstSafeCellInColumn();
		//save it to the row variable
		row <- safeRow;
		//log the found row for debugging and logging
		write name + ": Found row: " + row;
		//if we couldn't find a row (marked with -1), we try to rearrange previous queens
		if(row = -1){
			//defensive coding, this shouldn't happen, but only send the rearrange message if it is not the first queen
			if(col != 0){
				do start_conversation with:(to: list(Queen[col-1]), protocol: 'fipa-propose', performative: 'inform', contents: ['rearrange']);
			}
			//fail-fast return
			return;
		}
		//if we found a row, set the cell for the queen and tell the next queen to find a cell
		do setCell;
		//the problem is solved, if the last queen was placed
		if(col = N-1){
			done <- true;
		//otherwise send the message to the next queen along with the currently taken spots
		} else {
			do start_conversation with:(to: list(Queen[col+1]), protocol: 'fipa-propose', performative: 'inform', contents: ['find', taken]);
		}
	}
	
	/**
	 * Helper action for finding the first possible cell in the current queen's column
	 */
	int firstSafeCellInColumn{
		//if we were already in the last row, we need to rearrange previous queens
		if(row = N-1){
			return -1;
		}
		//try from the next row to the last with everything
		loop currRow from: row+1 to: N-1{
			//check if the specified cell is good
			if(feasible(currRow)){
				//return the row, if it is feasible
				return currRow;
			}
		}
		//return -1 if we couldn't find any possible cell in the column
		return -1;
	}
	
	/**
	 * Helper function for deciding if a cell is feasible with respect to the current state of the board
	 */
	bool feasible(int r){
		//if it is already occupied, of course it is not possible to place anything there
		if((col::r) in taken){
			return false;
		}
		//go over the occupied cells, and check if they are in conflict based on the queen's rules
		loop o over: taken{
			//row or column is the same
			if(col = o.key or r = o.value){
				return false;
			}
			//diagonally unfeasible = vertical and horizontal difference is the same
			int dr <- abs(r - o.value);
			int dc <- abs(col - o.key);
			if(dr = dc){
				return false;
			}
		}
		//if we couldn't find any reasons that would prevent us from placing on this cell, we can
		return true;
	}
	
	/**
	 * Helper action for setting the id (and the designated column) for the queen
	 */
	action setCol(int _col){
		col <- _col;
	}
	
	/**
	 * Helper action for setting the cell for the queen based on the col and row variables
	 */
	action setCell{
		//set the location of the queen to the location of the cell to align
		location <- ChessBoard[col, row].location;
		//extend the occupancy list
		add item:col::row to:taken;
		//log the designated cell for debugging and logging
		write name + ": [" + col + "," + row + "]";
	}
	
	/**
	 * The graphical representation of the Queen species.
	 */
	aspect default {
		//red circle, size depends on the number of queens
        draw circle(25/N) color: #red;
        //print the id on the circle as well
        draw string(col) size: 3 color: #white anchor: {0.5,0.5} font: font("Helvetica", 25*12/N, #bold);
    }
}