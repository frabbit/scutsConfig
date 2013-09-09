
package scuts.config;


import haxe.macro.MacroType;



typedef MyAppSettings = haxe.macro.MacroType<[
	scuts.config.ConfigBuilder.asSettings(
		{
			teamName : @:doc("Das Team") "The Team",
			teamPlayers : @:doc("Die Anzahl der Spieler im Team") 11,
			features : {
				hasTipGroup:true,
				testIt : context.features.hasTipGroup + "1"
			},

			wording : @:doc("Das Wording") {
				hello : "hello world",
				sub : 
				{
					french : "hey"
				},
				correctAnswers : 
					@:doc('Die korrekten Antworten') 
					"Korrekte Antworten Ä",

				myFunc : function (numTips:Int, total:Int) {
					return context.wording.correctAnswers() + ": " + numTips + "/" + total;
				},
				myHtmlEmail :{
					subject : "whatever",
					body : function (first, last) {
						return 'hallo $first $last, dies ist eine 
						automatische Email von uns
						' + context.wording.correctAnswers() + '
						Viele Gruesse
						${first}
						${context.teamName()}';
					}
				},
				
				myOtherEmail : scuts.config.LayeredConfigTest.Emails.myEmail


			}
		}, ["hello"],"AppSettings")	
]>;

typedef MyAppSettingsWording = hello.AppSettingsWording;


typedef Overlay = haxe.macro.MacroType<[scuts.config.OverlayConfigBuilder.overlaySettings({ 
	teamName : "AnotherTeamName", 
	wording : {
		correctAnswers : "Correct Answers No Umlauts",
		myFunc : function (numTips:Int, total:Int) {
			return "ÄÖÜ" + context.wording.correctAnswers() + ": " + numTips + "/" + total;
		},
	}
},
["scuts", "config"], "MyAppSettings", ["myoverlay"], "MyOverlaySettings")]>;





class Emails {
	public static var myEmail = "hello myEmail";
}

typedef MapOverlay = haxe.macro.MacroType<[scuts.config.MapOverlayBuilder.overlaySettings(["scuts", "config"], "MyAppSettings", ["mapoverlay"], "MapOverlaySettings")]>;

class LayeredConfigTest {
	


	public function new () {

	}

	public function testBasic () 
	{

		var x:MyAppSettings = new MyAppSettings(null);
		

		

		



		var o:MyAppSettings = Overlay.create(x);

		
		




		var o2 = Overlay.create(o);




		var map1 = new MapOverlay(o, [ "teamName" => "${wording.correctAnswers}: MapTeam"]);
		trace(map1.teamName());

		var map2:MyAppSettings = new MapOverlay(x, [ "teamName" => "${wording.correctAnswers}: ${teamPlayers}"]);


		trace(x.wording.myFunc(2,3));
		trace(o.wording.myFunc(2,1));


		trace(x.wording.myHtmlEmail.body("peter", "walter"));
		trace(o.wording.myHtmlEmail.body("peter", "walter"));
		trace(map1.wording.myHtmlEmail.body("peter", "walter"));
		trace(map2.wording.myHtmlEmail.body("peter", "walter"));


		

		//OverlayConfigBuilder.overlaySettings({ teamName : "AnotherTeamName"}, "AppSettings", x);
	}
		


}

