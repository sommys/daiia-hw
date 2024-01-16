# Homework Assignments for ID2209 Distributed Artificial Intelligence and Intelligent Agents course for the 2023 Fall semester

## Platform
For assignments 1-3 [GAMA 1.9.2](https://github.com/gama-platform/gama/releases/tag/1.9.2) was used.
For assignment 4 [AutoGen 0.2.3](https://pypi.org/project/pyautogen/0.2.3/) and GPT-4 API was used.

## Assignment1
Festival simulation where guests get hungry or thirsty. If they do, they should go to the Information Center to ask for the nearest store that gives them what they need. Afterward, the guests should simply keep doing something until they get hungry/thirsty again.
### Challenge1
Small brain for the guests, so they remember the stores they have visited before, and sometimes go to a previously visited one, and other times ask for a new one at the InformationCenter, so they get to explore more of the festival.
### Challenge2
Bad behavior for the Guests based on some randomness and event and add a Security Guard species that can take care of such guests in form of removing them from the festival.

## Assignment2
Auction simulation for an object at a festival. An auctioneer pops up at a random time at the festival and announces the start of the auction, and the guests gather around him to participate in a Dutch auction for the item. Once the auction is over, the agents get back to partying.
### Challenge1
Auctions for multiple items, and guests have a preferred item, for which they are willing to joint the auction, but not for the others.
### Challenge2
Extend the possible auction types with the English auction, Sealed-bid auction, and the Vickrey auction.

## Assignment3
### Task1
Solving the N-Queen problem with the queens being the agents. They can only communicate with their adjacent queens and have to coordinate each other to solve the N-Queen problem (placing N queens on an NxN chess table without conflicts).
### Task2
Festival simulation where different stages are available, and the guests decide on which one to visit based on multiple attributes and their preferences (utility function).
#### Challenge
Create a Leader agent, that is responsible for coordinating the preferences of anti-social and social guests based on their ranking and optimize global utility.

## Assignment4 (Final Project)
Use AutoGen to implement agent-based Dutch auction using Large Language Models (GPT-4).
#### Challenge
Implement English, Sealed-Bid and Vickrey auctions and make the scenarios configurable.
