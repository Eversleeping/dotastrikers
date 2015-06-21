package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	import flash.events.*; 
    import flash.utils.Timer;

	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class Menu extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		var nextX:int = 0
		var nextY:int = 0
		var radioBtnHeight:Number
		var radioNames:Array
		var radioNamesToValveObjs:Object = new Object()
		var nameToMenuMCs:Object = new Object()
		var radioTxtFormat:TextFormat
		var stageW:int
		var stageH:int
		var yScale:Number
		var currentMenuMC:MovieClip

		public function Menu() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;

			radioTxtFormat = new TextFormat()
			radioTxtFormat.size = 16

			addEventListener(Event.ENTER_FRAME, myEnterFrame)

			radioNames = new Array(4) // # of radio buttons. remember to change this when new radio buttons are added.
			//nextX = 0
			
			for (var i:int = 0; i < numChildren; i++) {
				var e:MovieClip = getChildAt(i) as MovieClip;
				if (e != null && e.name != null) {
					if (Util.startsWith(e.name, "radio")) {
						var index:int = parseInt(e.name.substr(5,1))
						radioNames[index] = e.name
					}
				}
			}

			for (i = 0; i < radioNames.length; i++) {
				setupRadioButton(getChildByName(radioNames[i]) as MovieClip)
			}

			//x = stageW/2-nextX/2
			x=0
			y = 44*yScale

			for (var k:String in nameToMenuMCs) {
				var mc:MovieClip = nameToMenuMCs[k]
				mc.x = 0
				mc.y = 3*yScale
				if (k == "Home") {
					mc.visible = true
					currentMenuMC = mc
				}

			}

			//bodyText.htmlText = Globals.instance.GameInterface.Translate("#WelcomeToDotaStrikers")

			home.setup(gameAPI, globals, this)
			options.setup(gameAPI, globals)
			learn.setup(gameAPI, globals)
			credits.setup(gameAPI, globals)

			trace("##Called Menu Setup!");
		}
		
		public function setupRadioButton(btn) {
			var str:String = btn.name
			var name:String = str.substr(7, str.length-7)
			var tmp:Object = replaceWithValveComponent(btn, "d_RadioButton_2nd");
			radioNamesToValveObjs[name] = tmp
			tmp.label = Globals.instance.GameInterface.Translate("#" + name)
			tmp.addEventListener(ButtonEvent.CLICK, onRadioBtnClicked)
			trace("setup valve component: " + name)

			tmp.x = nextX
			nextX = nextX + tmp.width
			radioBtnHeight = tmp.height

			var mc:MovieClip = getChildByName(name.toLowerCase()) as MovieClip
			nameToMenuMCs[name] = mc

			if (name == "Home") {
				// make it highlighted at the start.
				tmp.selected = true
				//tmp.toggle = true
				//Util.PrintTable(tmp)
			}
		}

		private function myEnterFrame(e:Event) : void {
			for (var k:String in radioNamesToValveObjs) {
				if (radioNamesToValveObjs[k].textField.getTextFormat() != radioTxtFormat) {
					radioNamesToValveObjs[k].textField.setTextFormat(radioTxtFormat)
				}
			}
		}

		public function onGameOver() : void {
			options.onGameOver()
			credits.onGameOver()

			if (!visible) {
				visible = true
			}

			changeMenuPanel("Credits")

		}

        public function onRadioBtnClicked(e:ButtonEvent)
        {
			changeMenuPanel(e.target.label)
        }

        public function changeMenuPanel(mName:String) : void {
			var mc:MovieClip = nameToMenuMCs[mName]
			currentMenuMC.visible = false
			currentMenuMC = mc
			mc.visible = true
			//gameAPI.SendServerCommand("play_sound ui.click_toptab")
			trace(mc.name + " is now visible. ")
			if (!radioNamesToValveObjs[mName].selected) {
				radioNamesToValveObjs[mName].selected = true
			}

        }

        public function getCurrentMenuMC():MovieClip {
        	return currentMenuMC
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
			width = width*yScale
			height = height*yScale

			this.stageW = stageW
			this.stageH = stageH

			// this is always called at the resolution the player is currently at.
			//x = stageW/2-width/2;
			//y = stageH/2 - height/2-45*yScale;
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			scaleX = xScale
			scaleY = yScale

			this.yScale = yScale

			home.screenResize(stageW, stageH, yScale, yScale, wide)
			options.screenResize(stageW, stageH, yScale, yScale, wide)
			learn.screenResize(stageW, stageH, yScale, yScale, wide)
			credits.screenResize(stageW, stageH, yScale, yScale, wide)
		}
	}	
}

