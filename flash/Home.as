package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	//import scaleform.clik.controls;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	import flash.events.TimerEvent; 
    import flash.utils.Timer; 

	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class Home extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		var _scrollBar:Object

		public function Home() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			// Font Labels
			var txFormatBold:TextFormat = new TextFormat;
			txFormatBold.font = "Radiance-Semibold";
			var txFormatTitle:TextFormat = new TextFormat;
			txFormatTitle.font = "$TitleFontBold";

			//bodyText.htmlText = Globals.instance.GameInterface.Translate("#WelcomeToDotaStrikers")

			//_scrollBar = replaceWithValveComponent(scrollBar, "ScrollBarDota");
			//_scrollBar.scrollTarget = bodyText
			//_scrollBar.direction = ScrollBarDirection.VERTICAL
			//_scrollBar.addEventListener(Event.SCROLL, onScrollBarScroll);

			trace("##Called Home Setup!");
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
			//trace("Stage Size: ",stageW,stageH);

			//width = width*yScale;
			//height = height*yScale;

			// this is always called at the resolution the player is currently at.
			//x = stageW/2 - width/2;
			//y = stageH/2 - height/2-45*yScale;
			
			//trace("#Result Resize: ",x,y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			//scaleX = xScale;
			//scaleY = yScale;
		}
	}	
}

