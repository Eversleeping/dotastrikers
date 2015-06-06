﻿package {
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
		//var _menuButton:Object

		//constructor, you usually will use onLoaded() instead
		public function Multiboard() : void {
	
		}

		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			trace("[Multiboard] OnLoaded")

			visible = false

			//gameAPI.SubscribeToGameEvent("toggle_show_ability_silenced", toggleSilenceAbility);

			Globals.instance.resizeManager.AddListener(this);

			//Globals.instance.GameInterface.SetConvar("dota_always_show_player_names", "1")

			//pass the gameAPI on to the modules
			//learn_about_heroes.setup(gameAPI, globals)

			addEventListener(Event.ENTER_FRAME, myEnterFrame)

			trace("[Multiboard] OnLoaded finished!");
		}

		/*public function toggleSilenceAbility(args:Object) : void {

			if (globals.Players.GetLocalPlayer() != args.player_ID)
			{
				return
			}

			var i:Number = args.ability_index
			var silencedState:MovieClip = null
			var isVisible:Boolean = false

			if (i == 2) {
				//trace("captured silencedState")
				silencedState = globals.Loader_actionpanel.movieClip.middle.abilities.Ability2.silencedState
			} else if (i == 3) {
				silencedState = globals.Loader_actionpanel.movieClip.middle.abilities.Ability3.silencedState
			} // ... extend this

			isVisible = silencedState.visible

			if (isVisible) {
				trace("setting silencedState to false")
				silencedState.visible = false
			} else {
				trace("setting silencedState to true")
				silencedState.visible = true
			}
		}*/

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
			//learn_about_heroes.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
		}
	}
}