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
	
	public class CustomUI extends MovieClip {
		
		//these three variables are required by the engine
		public var gameAPI:Object
		public var globals:Object
		public var elementName:String
		
		// resizing stuff
		private var ScreenWidth:int
		private var ScreenHeight:int
		public var scaleRatioY:Number
		var menuButtonTxtFormat:TextFormat

		// my vars
		//var map:Dictionary = new Dictionary();
		var _menuButton:Object

		//constructor, you usually will use onLoaded() instead
		public function CustomUI() : void {
	
		}

		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			trace("[CustomUI] OnLoaded");
			
			//ds_menu.visible = false

			menuButtonTxtFormat = new TextFormat()
			menuButtonTxtFormat.size = 14

			visible = true;

			gameAPI.SubscribeToGameEvent("toggle_show_ability_silenced", toggleSilenceAbility)
			gameAPI.SubscribeToGameEvent("all_players_loaded", onAllPlayersLoaded)
			gameAPI.SubscribeToGameEvent("game_over", onGameOver)
			gameAPI.SubscribeToGameEvent("hero_picked", onHeroPicked)

			var oldChatSay:Function = globals.Loader_hud_chat.movieClip.gameAPI.ChatSay;
			globals.Loader_hud_chat.movieClip.gameAPI.ChatSay = function(obj:Object, bool:Boolean){
				var type:int = globals.Loader_hud_chat.movieClip.m_nLastMessageMode
				if (bool)
					type = 4
				
				gameAPI.SendServerCommand( "player_say " + type + " " + obj.toString());
				oldChatSay(obj, bool);
			};

			Globals.instance.resizeManager.AddListener(this)

			Globals.instance.GameInterface.SetConvar("dota_always_show_player_names", "1")
			Globals.instance.GameInterface.SetConvar("dota_hud_healthbar_number", "0")

			// these prevent tooltips from fcking up at the start
			//Globals.instance.GameInterface.SetConvar("dota_render_crop_height", "0")
			//Globals.instance.GameInterface.SetConvar("dota_draw_portrait", "0")

			//pass the gameAPI on to the modules
			ds_menu.setup(gameAPI, globals)

			_menuButton = replaceWithValveComponent(menuButton, "chrome_button_primary")
			_menuButton.addEventListener(ButtonEvent.CLICK, onMenuButtonClicked)
			_menuButton.label = "MENU"
			//_menuButton.height = _menuButton.height + _menuButton.height*1/4
			_menuButton.visible = true
			ds_menu.visible = true

			addEventListener(Event.ENTER_FRAME, myEnterFrame)

			trace("[CustomUI] OnLoaded finished!");
		}

		public function onMenuButtonClicked(event:ButtonEvent) {
			if (ds_menu.visible) {
				ds_menu.visible = false
				if (ds_menu.getCurrentMenuMC()) {
					ds_menu.getCurrentMenuMC().visible = false
				}
				gameAPI.SendServerCommand("play_sound Close_Menu")
			} else {
				ds_menu.visible = true
				if (ds_menu.getCurrentMenuMC()) {
					ds_menu.getCurrentMenuMC().visible = true
				}
				gameAPI.SendServerCommand("play_sound Open_Menu")
			}
		}

		public function onAllPlayersLoaded() : void {
			ds_menu.visible = false
			if (ds_menu.getCurrentMenuMC()) {
				ds_menu.getCurrentMenuMC().visible = false
			}
		}

		public function onHeroPicked(args:Object) : void {
			if (globals.Players.GetLocalPlayer() != args.player_ID)
			{
				return
			}
			trace("onHeroPicked")
			//Globals.instance.GameInterface.SetConvar("dota_render_crop_height", "1")
			//Globals.instance.GameInterface.SetConvar("dota_draw_portrait", "1")
		}

		public function onGameOver() : void {
			ds_menu.onGameOver()
		}

		public function toggleSilenceAbility(args:Object) : void {

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
		}

		private function myEnterFrame(e:Event) : void {
			globals.Loader_actionpanel.movieClip.middle.invokeListButton.visible = false
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
			
			trace("[CustomUI] ##### RESIZE #########");
					
			ScreenWidth = re.ScreenWidth;
			ScreenHeight = re.ScreenHeight;

			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			ds_menu.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());

			menuButton.x = 243*scaleRatioY;
			menuButton.y = 6*scaleRatioY;

		}
	}

	//function resize()

}