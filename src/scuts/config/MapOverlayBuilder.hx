
package scuts.config;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

class MapOverlayBuilder {


	
	public static function subOverlayFields (fieldName:String, subTypeName:String, overlayPack:Array<String>, subOverlayName:String):Array<Field> 
	{

		
		var eNew = { expr : ENew({ name : subOverlayName, params : [], pack : []}, [macro this.parent.$fieldName, macro this.context, macro this._map]), pos : Context.currentPos() };
		

		var newFun = 
			macro function () {
				if ($i{fieldName} == null) {
					$i{fieldName} = $eNew;
				}
				return $i{fieldName};
			};

		var f = switch (newFun.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			
			{
				name : "get_" + fieldName,
				access : [APrivate, AOverride],
				kind : FFun(f),
				pos : Context.currentPos()
			}
		];

		return fields;
		
	}

	public static function baseTypeDef (pack:Array<String>, name:String, overlayPack:Array<String>, overlayName:String):TypeDefinition 
	{

		var cName = overlayName;

		var ct = ComplexType.TPath({ pack : pack, name : name, params : []});

		var constructor = 
			macro function (parent:$ct, map:Map<String,Dynamic>) {
				super(parent);
				this._map = map;
				
			};
		var f = switch (constructor.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			{
				name : "_map",
				access : [APrivate],
				kind : FieldType.FVar(null,macro null),
				pos : Context.currentPos()
			},
			{
				name : "new",
				access : [APublic],
				kind : FFun(f),
				pos : Context.currentPos()
			}
		];

		return {
			pack :overlayPack,
			name : cName,
			pos : Context.currentPos(),
			meta : [],
			params : [],
			isExtern : false,
			kind : TDClass({ pack : pack, name : name, params:[]}),
			fields : fields
		}
		
	}

	public static function subTypeDef (pack:Array<String>, name:String, overlayPack:Array<String>, overlayName:String, contextName:String):TypeDefinition 
	{

		var cName = overlayName;


		var ct = ComplexType.TPath({ pack : pack, name : name, params : []});

		var constructor = 
			macro function (parent:$ct, context, map:Map<String,Dynamic>) {
				super(parent, context);
				this._map = map;
				
			};
		var f = switch (constructor.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			{
				name : "_map",
				access : [APrivate],
				kind : FieldType.FVar(null,macro null),
				pos : Context.currentPos()
			},
			{
				name : "new",
				access : [APublic],
				kind : FFun(f),
				pos : Context.currentPos()
			}
		];

		return {
			pack :overlayPack,
			name : cName,
			pos : Context.currentPos(),
			meta : [],
			params : [],
			isExtern : false,
			kind : TDClass({ pack : pack, name : name, params:[]}),
			fields : fields
		}
		
	}



	public static function overlaySettings (pack:Array<String>, name:String, overlayPack:Array<String>, overlayName : String):Type {
		
		var t = Context.follow(Context.getType(pack.join(".") + (if (pack.length > 0) "." else "") + name),false);
		

		return switch (t) {
			case TInst(t1,_):
				var name = t1.get().name;
				var pack = t1.get().pack;

				makeOverlayType(t,pack, name, overlayPack, overlayName);
			case _:
				throw "assert";
		}

		

				
	}


	public static function makeOverlayType(t:Type, pack:Array<String>, name:String, overlayPack:Array<String>, overlayName:String, mapPrefix:String = ""):Type
	{
		var td = baseTypeDef(pack, name, overlayPack, overlayName);
		function switchType(t1) return switch (t1) 
		{
			case TInst(t,_):
				makeOverlaySettingsFromFields(t.get().fields.get(), pack, name, name, overlayPack, overlayName, mapPrefix);
			case TLazy(f): switchType(f());
			case _:
				throw "Invalid";
		}

		var fields = switchType(t);
		td.fields = td.fields.concat(fields);

		var clName = overlayPack.join(".") + (if (overlayPack.length > 0) "." else "") + overlayName;

		

		Context.defineType(td);

		return Context.getType(clName);
	}

	public static function makeOverlaySettingsFromFields (clFields:Array<ClassField>, pack:Array<String>, name:String, rootName:String, overlayPack:Array<String>, overlayName:String, mapPath:String):Array<Field> 
	{
		var f1Fields = clFields;

		var newFields:Array<Field> = [];

		

		for (f1 in f1Fields) {
			

			switch f1.kind {
				case FVar(_,_) if (f1.name != "_map" && f1.name != "context" && f1.name != "parent"):
					
					function switchType (t1) 
					{
						switch (t1) {
							case TInst(t,_):
								var clFields = t.get().fields.get();
								var subName = name + f1.name.charAt(0).toUpperCase() + f1.name.substr(1);
								var subOverlayName = overlayName + f1.name.charAt(0).toUpperCase() + f1.name.substr(1);
								var td = subTypeDef(pack, subName,overlayPack, subOverlayName,rootName);
								var subMapPath = mapPath + (if (mapPath.length > 0) "." else "") + f1.name;
								var fields = makeOverlaySettingsFromFields(clFields, pack, subName, rootName, overlayPack, subOverlayName, subMapPath);



								td.fields = td.fields.concat(fields);

								Context.defineType(td);

								newFields = newFields.concat(subOverlayFields(f1.name, subName, overlayPack, subOverlayName));


							case _: 
								throw "invalid";
						}
					}
					switchType(f1.type);



				case _:
					function switchType (t1) {
						
						switch (t1) {
							case TLazy(f): switchType(f());
							case TFun(args,ret) if (!StringTools.startsWith(f1.name, "get_") && !StringTools.startsWith(f1.name, "_")) :
								
								var fields = createField(f1.name, args, ret, mapPath);
								newFields = newFields.concat(fields);

							
							case _:
								


						}
						
					}
					switchType(f1.type);
			}
		}
		

		return newFields;
		
	}


	

	public static function createField (fieldName:String, args:Array<{t:Type, opt:Bool, name:String}>, ret:Type, mapPath:String):Array<Field> 
	{
		
								
		var callArgs = args.map(function (x) return macro $i{x.name});
		var fieldPath = mapPath + (if (mapPath.length > 0) "." else "") + fieldName;

		var convertVal = switch (ret) {
			case TInst(cl,[]) if (cl.get().name == "String"):
				macro 
					var res = switch (Type.typeof(mapVal)) {
						case TClass(c) if (Type.getClassName(c) == "String"):
							
							scuts.config.ConfigTools.replaceMapDynamic(mapVal, this.context);
						case _:
							throw "Runtime Exception cannot convert " + Std.string(mapVal) + " to String";
					}		
				
			case TAbstract(ab,[]) if (ab.get().name == "Int"):
				macro
					var res = switch (Type.typeof(mapVal)) {
						case TInt:
							mapVal;
						case TClass(c) if (Type.getClassName(c) == "String"):
							var x = Std.parseInt(mapVal);
							if (mapVal == null) throw "Runtime Exception cannot convert " + Std.string(mapVal) + " to Int";
							x;
						case _:
							throw "Runtime Exception cannot convert " + Std.string(mapVal) + " to Int";
					}		
				
			case TAbstract(ab,[]) if (ab.get().name == "Float"):
				macro 
					var res = switch (Type.typeof(mapVal)) {
						case TFloat:
							mapVal;
						case TInt:
							var x:Float = mapVal;
							x;
						case TClass(c) if (Type.getClassName(c) == "String"):
							var x = Std.parseFloat(mapVal);
							if (mapVal == null) throw "Runtime Exception cannot convert " + Std.string(mapVal) + " to Float";
							x;
						case _:
							throw "Runtime Exception cannot convert " + Std.string(mapVal) + " to Float";
					}		
				
			case TAbstract(ab,[]) if (ab.get().name == "Bool"):
				macro 
					var res = switch (Type.typeof(mapVal)) {
						case TBool:
							mapVal;
						case TClass(c) if (Type.getClassName(c) == "String"):
							var mapValStr:String = mapVal;
							var x = if (mapValStr.toLowerCase() == "true") true else if (mapValStr.toLowerCase() == "false") false else null;
							if (mapVal == null) throw "Runtime Exception cannot convert " + Std.string(mapVal) + " to Bool";
							x;
						case _:
							throw "Runtime Exception cannot convert " + Std.string(mapVal) + " to Float";
					}		
				
			case _:
				null;
		}

		return if (convertVal != null) 
		{
			var funExpr = macro function () {
				var mapVal = this._map.get($v{fieldPath});
				if (mapVal != null) {
					$convertVal;
					return res;
				} else {
					return super.$fieldName($a{callArgs});
				}
			}

			var fun = switch (funExpr.expr) {
				case EFunction(_,f): 
					f.args = args.map(function (x) {
						return {
							name : x.name,
							type : TypeTools.toComplexType(x.t),
							opt : x.opt,
							value : null
						}
					});
					f;
				case _ : throw "assert";
			}
			var field:Field = 
			{
				name : fieldName,
				access : [AOverride, APublic],
				kind : FFun(fun),
				pos : Context.currentPos()
			};
			[field];
		} else [];
		
	}





}

#end