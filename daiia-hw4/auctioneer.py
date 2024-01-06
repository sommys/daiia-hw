from autogen import AssistantAgent, Agent, GroupChat
from typing import Optional, List, Dict, Any
from config import llm_config, rules_auctioneer

class Auctioneer(AssistantAgent):
    def __init__(self, auction_type, _llm_config=llm_config):
        super().__init__(
            name="Auctioneer",
            system_message=self._sys_msg(auction_type),
            llm_config=_llm_config
        )
        self.auction_type = auction_type
        self.register_reply('Bidder', self._auctioneer_reply)
    
    def _auctioneer_reply(self, messages: Optional[List[Dict]] = None, sender: Optional[Agent] = None, config: Optional[Any] = None):
        message = self.generate_reply(messages, sender, exclude=[self._auctioneer_reply])
        if message is None:
            return True, None
        else:
            return True, message
    
    def _sys_msg(self, auction_type):
        if auction_type not in rules_auctioneer.keys():
            raise ValueError(f"Invalid auction type: {auction_type}")
        sys_msg = f"You are an auctioneer selling an item at a {auction_type} Auction.\n"
        sys_msg += rules_auctioneer[auction_type]
        return sys_msg