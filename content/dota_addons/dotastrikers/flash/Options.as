﻿package  {
	import flash.display.MovieClip;
	import scaleform.clik.events.*;
	import flash.utils.getDefinitionByName;
	import flash.events.*; 

	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class Options extends MovieClip {
		
		public var gameAPI:Object
		public var globals:Object
		var _camDistSlider:Object
		var optionsKV:Object
		var newOptionsKV:Object = new Object()
		var currCamDist:int = 2000
		var currDistLabelT:String // currDistLabel translated

		public function Options() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api
			this.globals = globals

			// set this to at least 2000 above the max slider value.
			// it's necessary for the game to render properly while zooming
			Globals.instance.GameInterface.SetConvar("r_farz", "7000")

			optionsKV = globals.GameInterface.LoadKVFile('resource/flash3/dotastrikers_options.kv')

			addEventListener(Event.ENTER_FRAME, myEnterFrame)

			camDistLabel.text = Globals.instance.GameInterface.Translate("#CamDistLabel")
			currDistLabelT = Globals.instance.GameInterface.Translate("#CurrDistLabel")
			currDistLabel.text = currDistLabelT
			yourSettingsWill.text = Globals.instance.GameInterface.Translate("#YourSettingsWill")

			_camDistSlider = replaceWithValveComponent(camDistSlider, "Slider_New", true)
			_camDistSlider.minimum = 900
			_camDistSlider.maximum = 4000
			_camDistSlider.value = 2000
			_camDistSlider.snapping = true
			_camDistSlider.snapInterval = 10
			_camDistSlider.addEventListener( SliderEvent.VALUE_CHANGE, onCamDistSliderChanged )

			if (optionsKV != null) {
				if (optionsKV["CameraDistance"]) {
					var dist:int = parseInt(optionsKV["CameraDistance"])
					if (!isNaN(dist)) {
						trace("Saved CameraDistance found. value: " + dist)
						_camDistSlider.value = dist
					}

				}
			}

			trace("##Called Options Setup!");
		}

		public function onGameOver() : void {
			trace("onGameOver Options")

			newOptionsKV["CameraDistance"] = String(currCamDist)

			Globals.instance.GameInterface.SaveKVFile(newOptionsKV, 'resource/flash3/dotastrikers_options.kv', 'Options')

		}

		public function onCamDistSliderChanged(e:SliderEvent) {
			/*var currVal:int = _camDistSlider.value
			trace("Current value: " + currVal)
			currCamDist = currVal*/
		}

		private function myEnterFrame(e:Event) : void {
			//trace("myEnterFrame Options")
			currCamDist = _camDistSlider.value
			Globals.instance.GameInterface.SetConvar("dota_camera_distance", currCamDist.toString())
			currDistLabel.text = currDistLabelT + " " + currCamDist
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

