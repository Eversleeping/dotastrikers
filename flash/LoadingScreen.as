package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	import flash.events.TimerEvent; 
    import flash.utils.Timer; 

	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class LoadingScreen extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		public var heroes:Array = new Array("slam","powershot","blackhole","tackle","sprint", "pull", "swap")
		var currentHeroMC:MovieClip;
		var currentHeroInfoMC:MovieClip

		var _gotItBtn:Object;

		public function LoadingScreen() {
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

			for (var i:int = 0; i < heroes.length; i++) {
				var hero:MovieClip = getChildByName(heroes[i]) as MovieClip
				hero.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOverHero);
				hero.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOutHero);
			}

			trace("##Called LoadingScreen Setup!");
		}

		public function onMouseRollOverHero(keys:MouseEvent) {
       		var hero:MovieClip = keys.target as MovieClip;
       		currentHeroMC = hero
       		var heroName:String = keys.target.name
       		var heroInfo:MovieClip = getChildByName(heroName + "_Info") as MovieClip
       		heroInfo.visible = true
       		currentHeroInfoMC = heroInfo
       		trace("roll over! " + heroName);

			// Workout where to put it
           // var lp:Point = rune.localToGlobal(new Point(0, 0));
			
           // globals.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, runeName);
       	}
		
		public function onMouseRollOutHero(keys:MouseEvent) {
			var heroName:String = keys.target.name
			var heroInfo:MovieClip = getChildByName(heroName + "_Info") as MovieClip
			heroInfo.visible = false
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
			trace("Stage Size: ",stageW,stageH);

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = 0
			this.y = 30*yScale
			
			trace("#Result Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
	}	
}

