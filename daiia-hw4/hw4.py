from argparse import ArgumentParser
from json import load
from random import randint, uniform as randfloat

from autogen import GroupChatManager

from auctioneer import Auctioneer
from bidder import Bidder
from auction_group_chat import AuctionGroupChat
from config import llm_config

def main() -> None:
    args = process_arguments()
    bidder_configs = parse_bidder_config(args.bidder_config, args.bidder_num, args.item_value, args.auction_type)
    
    if len(bidder_configs) != args.bidder_num:
        raise ValueError("Number of bidders in the configuration file does not match the number of bidders specified in the arguments.")

    auction_type = args.auction_type
    
    bidders = []
    for i in range(0, args.bidder_num):
        bidders.append(Bidder(auction_type=auction_type, bidder_config=bidder_configs[i]))
    
    auctioneer = Auctioneer(auction_type)
    
    all_agents = [auctioneer] + bidders
    
    groupchat = AuctionGroupChat(agents=all_agents, messages=[], max_round=100)
    manager = GroupChatManager(name="Auction Chat", groupchat=groupchat, llm_config=llm_config)
    auctioneer.initiate_chat(manager, message=f"Value of the item is {args.item_value} euros.")

def process_arguments() -> dict:
    """
    Processes the arguments passed to the script and returns them as a dictionary
    
    Returns:
        args (dict): Dictionary containing the arguments passed to the script
    """
    parser = ArgumentParser()
    parser.add_argument("-n", "--bidder_num", type=int, default=3, help="Number of bidders to be used (default: 3)")
    parser.add_argument("-t", "--auction_type", type=str, choices=["English", "Dutch", "Sealed-Bid", "Vickrey"], default="Dutch", help="Type of auction to be used (default: Dutch)")
    parser.add_argument("-v", "--item_value", type=int, default=100, help="Real value of the item to be sold (default: 100)")
    parser.add_argument("-c", "--bidder_config", type=str, default=None, help="Configuration file for the agents (default: None -> random configuration)")
    args = parser.parse_args()
    return args

def parse_bidder_config(config_file, bidder_num, item_value, auction_type) -> list:
    """
    Parses the configuration file for the bidders
    The file is in JSON format as a list, each element has the following structure:
        - id: int (required)
        - increment: int (optional)
        - limit: int (optional)
    If no file is provided, a random configuration is generated for all agents
    If a file is provided, but the number of configurations does not match the number of bidders, a random configuration is generated for missing bidders
    
    Args:
        config_file (str): Path to the configuration file
        bidder_num (int): Number of bidders
        item_value (int): Value of the item to be sold
        auction_type (str): Type of auction to be used
        
    Returns:
        bidder_configs (list): List of dictionaries containing the configuration for each bidder
    """
    #Generate random config if no file is provided
    if config_file == None:
        return generate_random_configs(bidder_num, item_value, auction_type)
    
    #Open the file and parse the data
    with open(config_file, 'r') as file:
        config_data = load(file)
    bidder_configs = []
    for config in config_data:
        bidder_id = config['id']
        increment = config.get('increment', None)
        limit = config.get('limit', None)
        config_dict = {'id': bidder_id}
        
        #Check if the configuration is valid for English and Dutch auctions
        if auction_type == "English":
            if increment == None:
                raise ValueError(f"Missing increment for bidder {bidder_id} in the configuration file.")
            else:
                config_dict['increment'] = increment
            if limit == None:
                raise ValueError(f"Missing limit for bidder {bidder_id} in the configuration file.")
            else:
                config_dict['limit'] = limit
        if auction_type == "Dutch":
            if limit == None:
                raise ValueError(f"Missing limit for bidder {bidder_id} in the configuration file.")
            else:
                config_dict['limit'] = limit
        
        bidder_configs.append(config_dict)
    
    #Generate random config for missing bidders
    ids = [config['id'] for config in bidder_configs]
    for id in range(1, bidder_num+1):
        if id not in ids:
            bidder_configs.append(generate_random_config(id, item_value, auction_type))
    #Sort the list by id
    bidder_configs = sorted(bidder_configs, key=lambda config: config['id'])
    return bidder_configs

def generate_random_configs(bidder_num, item_value, auction_type) -> list:
    """
    Generates random configurations for all bidders
    
    Args:
        bidder_num (int): Number of bidders
        item_value (int): Value of the item to be sold
        auction_type (str): Type of auction to be used
        
    Returns:
        bidder_configs (list): List of dictionaries containing the configuration for each bidder
    """
    bidder_configs = []
    for i in range(1, bidder_num+1):
        bidder_configs.append(generate_random_config(i, item_value, auction_type))
    return bidder_configs

def generate_random_config(i, item_value, auction_type) -> dict:
    """
    Generates a random configuration for the bidder with the given id
    
    Args:
        i (int): id of the bidder
        item_value (int): Value of the item to be sold
        auction_type (str): Type of auction to be used
        
    Returns:
        config (dict): Dictionary containing the configuration for the bidder
    """
    config = {'id': i}
    
    if auction_type == "English":
        config['increment'] = randint(1, round(item_value*0.05))
        config['limit'] = round(item_value*randfloat(1.1, 1.7))
    if auction_type == "Dutch":
        config['limit'] = round(item_value*randfloat(0.5, 0.8))
    
    return config

if __name__ == "__main__":
    main()