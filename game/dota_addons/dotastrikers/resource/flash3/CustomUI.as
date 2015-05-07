package {
	import flash.display.MovieClip;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.Timer; 

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class CustomUI extends MovieClip {
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var ScreenWidth:int;
		private var ScreenHeight:int;
		public var scaleRatioY:Number;

		//constructor, you usually will use onLoaded() instead
		public function CustomUI() : void {
	
		}

		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			//make this UI visible
			visible = true;
			trace("[CustomUI] OnLoaded");
			
			//this.gameAPI.SubscribeToGameEvent("show_main_ability", showMainAbility);

			var oldChatSay:Function = globals.Loader_hud_chat.movieClip.gameAPI.ChatSay;
			globals.Loader_hud_chat.movieClip.gameAPI.ChatSay = function(obj:Object, bool:Boolean){
				var type:int = globals.Loader_hud_chat.movieClip.m_nLastMessageMode
				if (bool)
					type = 4
				
				gameAPI.SendServerCommand( "player_say " + type + " " + obj.toString());
				oldChatSay(obj, bool);
			};

			Globals.instance.resizeManager.AddListener(this);

			Globals.instance.GameInterface.SetConvar("dota_always_show_player_names", "1")
			Globals.instance.GameInterface.SetConvar("dota_hud_healthbar_number", "0")
			//dota_hud_healthbar_number

			//pass the gameAPI on to the modules
			//scoreBoard.setup(gameAPI, globals);
			//waitForPlayers.setup(gameAPI, globals);

			//addEventListener(Event.ENTER_FRAME, myEnterFrame);

			trace("[CustomUI] OnLoaded finished!");
		}

		private function myEnterFrame(e:Event) : void {
			//trace("new frame.")
			
		}

		//this handles the resizes
		public function onResize(re:ResizeManager) : * {
			
			// calculate by what ratio the stage is scaling
			scaleRatioY = re.ScreenHeight/1080;
			
			trace("[CustomUI] ##### RESIZE #########");
					
			ScreenWidth = re.ScreenWidth;
			ScreenHeight = re.ScreenHeight;

			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			//scoreBoard.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			//waitForPlayers.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
		}
	}
}