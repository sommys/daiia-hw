from os import environ as env

config_list = [
    {
        'model': 'gpt-4',
        'api_key': env.get('OPENAI_KEY'),
    },
]

llm_config = {
    'temperature': 0.1,
    'config_list': config_list,
    'cache_seed': 4,
    'timeout': 60
}

rules_auctioneer = {
    'Dutch': "Start with a high price and gradually decrease it until a bidder accepts.\n"+
             "In case a bidder accepts, send back the winner and the 'END OF AUCTION' message.",
    'English': "Bidders openly compete by placing progressively higher bids.\n"+
               "In case nobody or only one bidder raised in the latest round, send back the winner and the 'END OF AUCTION' message.",
    'Sealed-Bid': "Bidders submit their bids privately in 1 round, highest bid wins.\n"+
                  "Evalute the bids, send back the winner, highest bid and the 'END OF AUCTION' message.",
    'Vickrey': "Bidders submit their bids privately in 1 round, highest bid wins, but only pays the second-highest bid.\n"+
               "Evalute the bids and send back the winner, the highest bid, the price to be paid and the 'END OF AUCTION' message.""",
}

rules_bidder = {
    'Dutch': "To accept the current offer, it should be less than {bidder_limit}.\n"+
             "When you accept the current offer, you send your id followed by the 'ACCEPT' message.\n"+
             "When you don't want to accept the offer, you send your id followed by the 'PASS' message.\n"+
             "If another bidder already accepted the offer, you cannot accept the offer and say 'Great Deal, Goodbye!'.",
    'English': "You always increase by {bidder_increment} and should not exceed {bidder_limit} with your bids.\n"+
               "When you raise the bid, you should reply with your id followed by the new amount proposed as plain text without any other symbol.\n"+
               "When you don't want to participate anymore, you send your id followed by the 'QUIT' message in plain text without any other symbol.",
    'Sealed-Bid': "You need to submit your bid once, by replying with your id followed by the proposed price.\n"+
                  "You must not consider other bidders' proposals, only consider the value proposed by the auctioneer to ensure private bidding.",
    'Vickrey': "You need to submit your bid once, by replying with your id followed by the proposed price.\n"+
               "You must not consider other bidders' proposals, only consider the value proposed by the auctioneer to ensure private bidding."
}