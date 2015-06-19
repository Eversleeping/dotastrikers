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
		
		public var gameAPI:Object
		public var globals:Object
		var _scrollBar:Object
		var _funModeCheckbox:Object
		var _learnAboutHeroesBtn:Object
		var parentMC:MovieClip

		public function Home() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object, _parentMC:MovieClip) {
			this.gameAPI = api;
			this.globals = globals;
			parentMC = _parentMC

			//_funModeCheckbox = replaceWithValveComponent(funModeCheckbox, "DotaCheckBoxDota")
			welcomeToLabel.text = Globals.instance.GameInterface.Translate("#WelcomeTo")
			alphaLabel.text = Globals.instance.GameInterface.Translate("#Alpha")
			howToPlayText.text = Globals.instance.GameInterface.Translate("#HowToPlayText")
			pleaseNote.text = Globals.instance.GameInterface.Translate("#PleaseNote")

			_learnAboutHeroesBtn = replaceWithValveComponent(learnAboutHeroesBtn, "ButtonThinPrimary", true)
			_learnAboutHeroesBtn.label = "LEARN MORE"
			_learnAboutHeroesBtn.addEventListener(ButtonEvent.CLICK, onLearnAboutHeroesBtnClick)


			trace("##Called Home Setup!");
		}

		public function onLearnAboutHeroesBtnClick(event:ButtonEvent) {
			trace("onLearnAboutHeroesBtnClick")
			gameAPI.SendServerCommand("play_sound ui.click_toptab")
			parentMC.changeMenuPanel("Learn")
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

