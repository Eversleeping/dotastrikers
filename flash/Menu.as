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
	
	public class Menu extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		var _optionsBtn:Object
		var _leaguesBtn:Object
		var _changelogBtn:Object
		var nextX:int
		var radioNames:Array

		public function Menu() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;

			//var radioNames:Object = new Object()
			radioNames = new Array(3) // # of radio buttons. remember to change this when new radio buttons are added.
			nextX = x
			
			for (var i:int = 0; i < numChildren; i++) {
				var e:MovieClip = getChildAt(i) as MovieClip;
				if (e != null && e.name != null) {
					if (Util.startsWith(e.name, "radio")) {
						var index:int = parseInt(e.name.substr(5,1))
						radioNames[index] = e.name
					}
				}
			}

			for (var i:int = 0; i < radioNames.length; i++) {
				setupRadioButton(getChildByName(radioNames[i]) as MovieClip)
			}

			//bodyText.htmlText = Globals.instance.GameInterface.Translate("#WelcomeToDotaStrikers")

			trace("##Called Menu Setup!");
		}
		
		public function setupRadioButton(btn) {
			var str:String = btn.name
			var name:String = str.substr(7, str.length-7)
			var tmp:Object = replaceWithValveComponent(btn, "d_RadioButton_2nd");
			tmp.label = name
			tmp["btn_name"] = name
			tmp.addEventListener(ButtonEvent.CLICK, onRadioBtnClicked);
			trace("setup valve component: " + name)

			tmp.x = nextX
			nextX = nextX + tmp.width

		}

        public function onRadioBtnClicked(e:ButtonEvent)
        {
			trace(e.target.label + " CLICK!")
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

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = stageW/2-this.width/2;
			this.y = stageH/2 - this.height/2-45*yScale;
			
			trace("#Menu Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
	}	
}

