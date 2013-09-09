
package scuts.config;

class ConfigTools {

	public static function replaceMapDynamic(s:String, baseContext:Dynamic) 
	{
		var ereg = ~/\$\{([a-zA-Z][a-zA-Z0-9_\.]*(\(\))?)\}/g;

		return ereg.map(s, function (ereg):String {
			var path = ereg.matched(1);
			
			
			var parts = path.split(".");
			
			var o:Dynamic = baseContext.context;
			for (i in 0...parts.length-1) {
				var p = parts[i];
				
				var val = Reflect.getProperty(o,p);
				
				if (val != null) {
					o = val;
					
				} else {
					throw "Runtime Context Exception, cannot find field " + p + " in " + o + " context " + baseContext;
				}
			}
			var lastField = Reflect.field(o, parts[parts.length-1]);

			if (Reflect.isFunction(lastField)) {
				
				o = Reflect.callMethod(o, lastField, []);

			} else {
				throw "the field " + path + " is not callable, but it should be.";
			}
			switch (Type.typeof(o)) {
				case TFunction: throw "Runtime Exception expr " + path + "() is a function and cannot be converted to string";
				case _:
			}
			return Std.string(o);
		});
	}
}
