package {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	import flash.events.*; 
    import flash.utils.Timer;
    import flash.text.TextFormat;

	//import some stuff from the valve lib
	import ValveLib.*;
	
	public class Multiboard extends MovieClip {
		
		//these three variables are required by the engine
		public var gameAPI:Object
		public var globals:Object
		public var elementName:String
		
		// resizing stuff
		private var ScreenWidth:int
		private var ScreenHeight:int
		public var scaleRatioY:Number

		// my vars
		var _mbButton:Object

		//constructor, you usually will use onLoaded() instead
		public function Multiboard() : void {
	
		}

		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			trace("[Multiboard] OnLoaded")

			//gameAPI.SubscribeToGameEvent("toggle_show_ability_silenced", toggleSilenceAbility);
			visible = true

			Globals.instance.resizeManager.AddListener(this);

			gameAPI.SubscribeToGameEvent("all_players_loaded", onAllPlayersLoaded)

			//Globals.instance.GameInterface.SetConvar("dota_always_show_player_names", "1")

			//pass the gameAPI on to the modules
			multiboard.setup(gameAPI, globals)

			_mbButton = replaceWithValveComponent(mbButton, "chrome_button_primary")
			_mbButton.addEventListener(ButtonEvent.CLICK, onMultiboardButtonClicked)
			_mbButton.label = "SCOREBOARD"
			//_mbButton.height = _mbButton.height + _mbButton.height*1/4
			_mbButton.visible = true

			addEventListener(Event.ENTER_FRAME, myEnterFrame)

			trace("[Multiboard] OnLoaded finished!");
		}

		public function onAllPlayersLoaded() : void {
			//multiboard.onAllPlayersLoaded()
		}

		public function onMultiboardButtonClicked(event:ButtonEvent) {
			if (multiboard.visible) {
				multiboard.visible = false
				/*if (ds_menu.getCurrentMenuMC()) {
					ds_menu.getCurrentMenuMC().visible = false
				}*/
				gameAPI.SendServerCommand("play_sound Close_Menu")
			} else {
				multiboard.visible = true
				/*if (ds_menu.getCurrentMenuMC()) {
					ds_menu.getCurrentMenuMC().visible = true
				}*/
				gameAPI.SendServerCommand("play_sound Open_Menu")
			}
		}

		private function myEnterFrame(e:Event) : void {
			/*if (_menuButton != null && _menuButton.textField.getTextFormat() != menuButtonTxtFormat) {
				_menuButton.textField.setTextFormat(menuButtonTxtFormat)
			}*/
		}

		public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip {
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
			
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) {
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
			
			parent.removeChild(mc);
			parent.addChild(newObject);
			
			return newObject;
		}

		//this handles the resizes
		public function onResize(re:ResizeManager) : * {
			
			// calculate by what ratio the stage is scaling
			scaleRatioY = re.ScreenHeight/1080;
			
			trace("[Multiboard] ##### RESIZE #########");
					
			ScreenWidth = re.ScreenWidth;
			ScreenHeight = re.ScreenHeight;

			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			multiboard.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());

			mbButton.x = ScreenWidth-460*scaleRatioY;
			mbButton.y = 6*scaleRatioY;

		}
	}
}