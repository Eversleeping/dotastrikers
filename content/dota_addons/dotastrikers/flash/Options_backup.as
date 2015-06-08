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
	
	public class Options extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		var _cameraZoomSlider:Object;
		var _saveBtn:Object
		var currCameraDistance:Number = 1800;

		public function Options() {
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

			//welcomeText.text = Globals.instance.GameInterface.Translate("#Welcome")
			//welcomeText.setTextFormat(txFormatBold);

			_cameraZoomSlider = replaceWithValveComponent(cameraZoomSlider, "Slider_New", true);
			_cameraZoomSlider.minimum = 300;
			_cameraZoomSlider.maximum = 4000;
			_cameraZoomSlider.value = 1800;
			_cameraZoomSlider.snapInterval = 50;
			_cameraZoomSlider.addEventListener( SliderEvent.VALUE_CHANGE, onCameraZoomSliderChanged );
			//addChild(_cameraZoomSlider)

			_saveBtn = replaceWithValveComponent(saveBtn, "chrome_button_primary", false);
			_saveBtn.addEventListener(ButtonEvent.CLICK, onSaveBtnClick);
			_saveBtn.label = "Save Settings"

			trace("##Called Options Setup!");
		}
		
		public function onCameraZoomSliderChanged(e:SliderEvent) {
			//this.gameAPI.SendServerCommand("zoom " + this.CameraSlider.value);
			//currCameraDistance = _cameraZoomSlider.value
			trace("Current value: " + _cameraZoomSlider.value)
			Globals.instance.GameInterface.SetConvar("dota_camera_distance", _cameraZoomSlider.value.toString())
		}

        public function onSaveBtnClick(event:ButtonEvent)
        {
        	//Globals.instance.GameInterface.SetConvar("dota_camera_distance", _cameraZoomSlider.value.toString())
			visible = false
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
			this.x = stageW/2-this.width/2;
			this.y = stageH/2 - this.height/2-30*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
	}	
}

