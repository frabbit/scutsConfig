
package scuts.config;

class AllTests {

	public static function main () 
	{
		var x = new utest.Runner();
		x.addCase(new apx.LayeredConfigTest());

		utest.ui.Report.create(x);

		x.run();

	}

}