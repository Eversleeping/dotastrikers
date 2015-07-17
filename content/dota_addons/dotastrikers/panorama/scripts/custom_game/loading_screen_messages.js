var LoadingScreenMessages = {
  intervalInSeconds: 10,

  index: 0,

  messages: [
    "To connect with other Strikers, play in leagues, tournaments, and more.",
    "Visit us in the forums at www.dotastrikers.com if you want to provide feedback and help make the game better."
  ],

  nextIndex: function() {
    this.index++;
    if (this.index >= this.messages.length) {
      this.index = 0
    }
  },

  showCurrentMessage: function() {
   $("#LoadingScreenMessageLabel").text = this.messages[this.index];
  },

  cycle: function() {
    this.showCurrentMessage();
    this.nextIndex();
    $.Schedule(this.intervalInSeconds, function() { LoadingScreenMessages.cycle(); });
  },
};

LoadingScreenMessages.showCurrentMessage();
GameEvents.Subscribe("game_newmap", function() { LoadingScreenMessages.cycle(); });