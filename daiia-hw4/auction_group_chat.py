from autogen import GroupChat

class AuctionGroupChat(GroupChat):
    def __init__(self, agents, messages, max_round=10):
        super().__init__(agents, messages, max_round)
        self.previous_speaker = None  
        self.speaker_idx = 0
        self.speaker_selection_method = 'round_robin'

    def select_speaker(self, last_speaker, selector):
        self.previous_speaker = last_speaker
        self.speaker_idx = self.speaker_idx + 1
        if self.speaker_idx >= len(self.agents):
            self.speaker_idx = 0
        return self.agents[self.speaker_idx]