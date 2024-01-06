import autogen
from typing import Optional, List, Dict, Any
from config import llm_config, rules_bidder

class Bidder(autogen.AssistantAgent):
    bidder_id: int
    
    def __init__(self, auction_type, bidder_config, _llm_config=llm_config):
        super().__init__(
            name=f"Bidder{bidder_config.get('id')}",
            system_message=self._sys_msg(
                bidder_id=bidder_config.get('id'),
                bidder_increment=bidder_config.get('increment', None),
                bidder_limit=bidder_config.get('limit', None),
                auction_type=auction_type
            ),
            is_termination_msg=lambda msg: 'END OF AUCTION' in msg['content'],
            llm_config=_llm_config
        )
        self.bidder_id = bidder_config.get('id')
        self.register_reply('Auctioneer', self._bidder_reply)
    
    def _bidder_reply(self, messages: Optional[List[Dict]] = None, sender: Optional[autogen.Agent] = None, config: Optional[Any] = None):
        message = self.generate_reply(messages, sender, exclude=[self._bidder_reply])
        if message is None:
            print("[DEBUG] No message for bidder " + str(self.bidder_id ))
            return True, None
        else:
            return True, message

    def _sys_msg(self, bidder_id, bidder_increment, bidder_limit, auction_type):
        if auction_type not in rules_bidder.keys():
            raise ValueError(f"Invalid auction type: {auction_type}")
        sys_msg = f"You are a bidder at a {auction_type} Auction looking to buy an item. Your id is {bidder_id}.\n"
        sys_msg += rules_bidder[auction_type]
        if auction_type == "Dutch":
            sys_msg = sys_msg.format(bidder_limit=bidder_limit)
        elif auction_type == "English":
            sys_msg = sys_msg.format(bidder_increment=bidder_increment, bidder_limit=bidder_limit)
        return sys_msg