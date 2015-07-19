"use strict";
var InfoToggled = false;

function OnToggleInfo() {
	if (InfoToggled == true) {
		InfoToggled = false;
		$.GetContextPanel().SetHasClass( "toggle_info_panel", false );
		Game.EmitSound( "ui_team_select_lock_and_start" );
	} else {
		InfoToggled = true;
		$.GetContextPanel().SetHasClass( "toggle_info_panel", true );
		Game.EmitSound( "ui_team_select_lock_and_start" );
	};
}

(function()
{
	
})();
