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
	import flash.text.TextField;
	
	public class MultiboardObj extends MovieClip {
		public var gameAPI:Object
		public var globals:Object

		var yScale:Number
		var sbLabelMCs:Object = new Object()
		var pIDToVals:Object = new Object()

		var abilities:Object
		var heroes:Object

		public function MultiboardObj() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;

			visible = false

			gameAPI.SubscribeToGameEvent("activate_player", onActivatePlayer)
			gameAPI.SubscribeToGameEvent("update_scoreboard_value", onUpdateScoreboardValue)

			abilities = globals.GameInterface.LoadKVFile('scripts/npc/npc_abilities_custom.txt');

			// get the sbLabel names
			for (var k:String in abilities) {
				if (startsWith(k, "sbLabel")) {
					sbLabelMCs[k] = new Object()
				}
			}

			// get the movieclips
			var i:int = 0
			for (i = 0; i < numChildren; i++) {
				var e:MovieClip = getChildAt(i) as MovieClip;
				if (e && e.name) {
					if (sbLabelMCs[e.name]) {
						sbLabelMCs[e.name] = e
						e.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOverSBLabel);
						e.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOutSBLabel);
					}
				}
			}
			
			var i2:int = 0
			for (i = 0; i < numChildren; i++) {
				var e2:TextField = getChildAt(i) as TextField;
				if (e2 && e2.text) {
					// hide all the numbers
					for (i2 = 0; i2 <= 9; i2++) {
						var s:String = "p" + i2
						if (startsWith(e2.name, s)) {
							e2.text = ""
						}
					}
				}
			}

			trace("##Called MultiboardObj Setup!");
		}

		public function onActivatePlayer(args:Object) : void {
			trace("onActivatePlayer")
			var pID:int = args.player_ID
			var playerName:String = args.player_name
			
			var i:int = 0
			for (i = 0; i < numChildren; i++) {
				var e2:TextField = getChildAt(i) as TextField;
				if (e2 && e2.text == "") {
					var s:String = "p" + pID
					if (startsWith(e2.name, s)) {
						if (e2.name.indexOf("name") >= 0) {
							e2.text = playerName
						} else {
							e2.text = "0"
						}
					}
				}
			}
			trace(pID + " activated!")
		}

		public function onUpdateScoreboardValue(args:Object) : void {
			var pID:int = args.player_ID
			var key:String = args.key
			var val:Number = args.value
			var _label:String = "p" + pID + key
			var tf:TextField = getChildByName(_label) as TextField

			if (key != "savp" && key != "poss") {
				val = trim(val, 0)
			} else {
				val = trim(val, 1)
			}

			var valStr:String = val.toString()

			if (key == "savp") {
				valStr += "%"
				if (val == -1) {
					valStr = "N/A"
				}
			}

			tf.text = valStr
			//trace("changed " + key + " to " + val)
		}

		public function onMouseRollOverSBLabel(keys:MouseEvent) {
       		var mc:MovieClip = keys.target as MovieClip;

            // Workout where to put it
            var lp:Point = mc.localToGlobal(new Point(mc.width*0.125*0.5, 0));

            //var offset = 0;
            //if(lp.x < stage.stageWidth/2) {
            //    offset = 60;
            //}

            // Workout where to put it
            //lp = mc.localToGlobal(new Point(offset, 0));

           	globals.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, mc.name);
       	}
		
		public function onMouseRollOutSBLabel(keys:MouseEvent) {
			globals.Loader_heroselection.gameAPI.OnSkillRollOut();
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
			trace("MultiboardObj. stageW: " + stageW + " stageH: " + stageH)
			this.yScale = yScale

			width = width*yScale;
			height = height*yScale;
			
			//trace("#Result Resize: ",x,y,yScale);
			
			x = stageW/2 - width/2;
			y = stageH/2 - height/2-60*yScale;

			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			scaleX = xScale;
			scaleY = yScale;
		}

        public function startsWith(haystack:String, needle:String):Boolean {
            return haystack.indexOf(needle) == 0;
        }

		public function trim(theNumber:Number, decPlaces:Number) : Number {
		    if (decPlaces >= 0) {
		        var temp:Number = Math.pow(10, decPlaces);
		        return Math.round(theNumber * temp) / temp;
		    }

		    return theNumber;
		} 
	}	
}

