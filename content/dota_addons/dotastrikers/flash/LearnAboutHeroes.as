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
	
	public class LearnAboutHeroes extends MovieClip {
		
		public var gameAPI:Object
		public var globals:Object
		var currentHeroMC:MovieClip;
		var currentHeroInfoMC:MovieClip
		var heroToAbils:Object = new Object()
		var heroToMC:Object = new Object()
		var heroToRealName:Object = new Object()
		var abilNameToImageName:Object = new Object()
		var stageW:int

		var abilities:Object
		var heroes:Object

		public function LearnAboutHeroes() {
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

			var tf:TextFormat = clickOnTheHeroes.getTextFormat()
			clickOnTheHeroes.text = Globals.instance.GameInterface.Translate("#ClickOnTheHeroes")

			abilitiesText.text = Globals.instance.GameInterface.Translate("#Abilities")

			//heroesLabel.defaultTextFormat = heroesLabel.getTextFormat()

			if (heroesLabel.filters == null) {
				trace("heroesLabel.filters is null.")
			}

			var _filters = heroesLabel.filters
			//heroesLabel.useRichTextClipboard = true
			//heroesLabel.text = Globals.instance.GameInterface.Translate("#Heroes")
			//heroesLabel.filters = _filters


			//hoverOverThem.text = Globals.instance.GameInterface.Translate("#HoverOverThem")
			heroNameText.text = Globals.instance.GameInterface.Translate("#HeroName")
			itemsLabel.text = Globals.instance.GameInterface.Translate("#Items")
			tip_1.text = Globals.instance.GameInterface.Translate("#Tip") + " #1:"
			tip_2.text = Globals.instance.GameInterface.Translate("#Tip") + " #2:"

			heroes = globals.GameInterface.LoadKVFile('scripts/npc/npc_heroes_custom.txt');
			abilities = globals.GameInterface.LoadKVFile('scripts/npc/npc_abilities_custom.txt');

			for (var i:int = 0; i < numChildren; i++) {
				var e:MovieClip = getChildAt(i) as MovieClip;
				if (e != null && e.name != null) {
					if (Util.startsWith(e.name, "hero")) {
						e.addEventListener(MouseEvent.CLICK, onMouseClickHero);
						var heroName:String = e.name.substr(5,e.name.length-5)
						//trace("heroName: " + heroName)
						heroToAbils[heroName] = new Array(6)
						heroToMC[heroName] = e

					} else if (Util.startsWith(e.name, "item")) {
						setupItem(e)
					}
					//trace("name: " + e.name)
				}
			}

			for (var k:String in heroes)
			{
				var v:String = heroes[k];
				if (heroToAbils[k] != null) {
					// find abils for this hero
					for (var k2:String in heroes[k]) {
						var abilName:String = heroes[k][k2]
						if (k2 == "Ability1") {
							//trace("Ability1: " + heroes[k][k2])
							heroToAbils[k][0] = abilName
						} else if (k2 == "Ability2") {
							heroToAbils[k][1] = abilName
						} else if (k2 == "Ability3") {
							heroToAbils[k][2] = abilName
						} else if (k2 == "Ability4") {
							heroToAbils[k][3] = abilName
						} else if (k2 == "Ability5") {
							heroToAbils[k][4] = abilName
						} else if (k2 == "Ability6") {
							heroToAbils[k][5] = abilName
						} else if (k2 == "DS_Name") {
							var realName:String = heroes[k][k2]
							// get rid of npc_dota_hero
							//realName = realName.substr(14, realName.length-14)
							// make first letter uppercase
							//realName = realName.substr(0,1).toUpperCase() + realName.substr(1,realName.length-1)

							heroToRealName[k] = realName.toString()
						}
						abilNameToImageName[abilName] = getAbilityTextureName(abilName)
					}
				}
			}

			onHeroClicked(getChildByName("hero_sprint"))

			trace("##Called LearnAboutHeroes Setup!");
		}

		public function setupItem(item) {
			var itemName:String = item.name
			globals.LoadImage("images/items/" + itemName.substr(5, itemName.length-5) + ".png", item, true);
			item["abil"] = itemName

			item.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOverAbility);
			item.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOutAbility);

		}

		public function onMouseClickHero(keys:MouseEvent) {
       		var hero:MovieClip = keys.target as MovieClip;
       		onHeroClicked(hero)
       		gameAPI.SendServerCommand("play_sound ui.browser_click_common")

       	}

       	public function onHeroClicked(hero) {
       		currentHeroMC = hero
       		var heroName:String = hero.name.substr(5,hero.name.length-5)
       		
       		var realName:String = heroToRealName[heroName]
       		trace("realName: " + realName)
       		heroNameText.text = Globals.instance.GameInterface.Translate("#HeroName") + " " + realName

       		for (var i:int=0; i < 6; i++) {
       			var mc:MovieClip = getChildByName("abil_" + i) as MovieClip
       			var abilName:String = heroToAbils[heroName][i]
       			globals.LoadImage("images/spellicons/" + abilNameToImageName[abilName] + ".png", mc, true);
       			mc["abil"] = abilName

				mc.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOverAbility);
				mc.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOutAbility);
       		}
       		trace("CLICK! " + heroName);
       	}

		public function onMouseRollOverAbility(keys:MouseEvent) {
       		var mc:MovieClip = keys.target as MovieClip;

            // Workout where to put it
            var lp:Point = mc.localToGlobal(new Point(mc.width*0.125*0.5, 0));

            var offset = 0;
            if(lp.x < stage.stageWidth/2) {
                offset = 60;
            }

            // Workout where to put it
            lp = mc.localToGlobal(new Point(offset, 0));

            // Decide how to show the info
            if(lp.x < stage.stageWidth/2) {
                // Face to the right
                globals.Loader_rad_mode_panel.gameAPI.OnShowAbilityTooltip(lp.x, lp.y, mc.abil);
            } else {
                // Face to the left
                globals.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, mc.abil);
            }
       	}
		
		public function onMouseRollOutAbility(keys:MouseEvent) {
			globals.Loader_heroselection.gameAPI.OnSkillRollOut();
		}

		public function getAbilityTextureName(abilName:String) {
			for (var k:String in abilities)
			{
				if (k == abilName) {
					for (var k2:String in abilities[k]) {
						if (k2 == "AbilityTextureName") {
							return abilities[k][k2]
						}
					}
				}
			}
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
			this.stageW = stageW

			width = width*yScale;
			height = height*yScale;
			
			//trace("#Result Resize: ",x,y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			scaleX = xScale;
			scaleY = yScale;

			// this is always called at the resolution the player is currently at.
			x = stageW - width/2;
			y = stageH - height/2;

		}
	}	
}

