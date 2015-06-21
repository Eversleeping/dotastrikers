package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	import flash.events.TimerEvent; 
    import flash.utils.Timer;
    import flash.geom.Point;

	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class Credits extends MovieClip {
		
		public var gameAPI:Object
		public var globals:Object
		var _exitGameBtn:Object

		public function Credits() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api
			this.globals = globals

			thankYou.text = Globals.instance.GameInterface.Translate("#ThankYou")
			creditsBody.text = Globals.instance.GameInterface.Translate("#CreditsBody")

			exitGameBtn.visible = false

			trace("##Called Credits Setup!");
		}

		public function onExitGameBtnClick(event:ButtonEvent) {
        	globals.Loader_gameend.movieClip.gameAPI.OnFinishButtonPress()
        	gameAPI.SendServerCommand("play_sound ui.click_toptab")
			//visible = false
		}

		public function onGameOver() : void {
			trace("onGameOver Credits")
			exitGameBtn.visible = true
			
			_exitGameBtn = replaceWithValveComponent(exitGameBtn, "ButtonThinPrimary", true)
			_exitGameBtn.label = Globals.instance.GameInterface.Translate("#Exit")
			_exitGameBtn.addEventListener(ButtonEvent.CLICK, onExitGameBtnClick)

		}

		//Parameters: 
		//	mc - The movieclip to replace
		//	type - The name of the class you want to replace with
		//	keepDimensions - Resize from default dimensions to the dimensions of mc (optional, false by default)
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

		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {
			
		}
	}	
}

