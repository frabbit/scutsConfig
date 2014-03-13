
package scuts.config;

using StringTools;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;


class OverlayConfigBuilder {


	
	
	

	
	
	public static function subOverlayFields (fieldName:String, subTypeName:String, overlayPack:Array<String>, subOverlayName:String):Array<Field> 
	{

		var fullName = subOverlayName;

		var newFun = 
			macro function () {
				if ($i{fieldName} == null) {
					$i{fieldName} = $i{fullName}.create(super.$fieldName, this.context);
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
			macro function (parent:$ct) {
				super(parent);
			};


		var eNew = { expr : ENew({ name : overlayName, params : [], pack : []}, [macro parent]), pos : Context.currentPos() };
		var staticCreateExpr = 
			macro function (parent:$ct):$ct {
				return $eNew;
				
			};

		var f = switch (constructor.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var staticCreate = switch (staticCreateExpr.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			{
				name : "new",
				access : [APrivate],
				kind : FFun(f),
				pos : Context.currentPos()
			},
			{
				name : "create",
				access : [APublic, AStatic],
				kind : FFun(staticCreate),
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
		

		var constructorExpr = 
			macro function (parent:$ct, context) {
				super(parent, context);
				
			};

		var eNew = { expr : ENew({ name : overlayName, params : [], pack : []}, [macro parent, macro context]), pos : Context.currentPos() };
		var staticCreateExpr = 
			macro function (parent:$ct, context):$ct {
				return $eNew;
				
			};
		var f = switch (constructorExpr.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}
		var staticCreate = switch (staticCreateExpr.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			{
				name : "new",
				access : [APrivate],
				kind : FFun(f),
				pos : Context.currentPos()
			},
			{
				name : "create",
				access : [APublic, AStatic],
				kind : FFun(staticCreate),
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

	

	public static function overlaySettings (e:Expr, pack:Array<String>, name:String, overlayPack:Array<String>, overlayName : String, requireAll : Bool = false):Type {
		
		var t = Context.follow(Context.getType(pack.join(".") + (if (pack.length > 0) "." else "") + name),false);
		

		return switch (t) {
			case TInst(t1,_):
				var name = t1.get().name;
				var pack = t1.get().pack;

				makeOverlayType(t,e, pack, name, overlayPack, overlayName, requireAll);
			case _:
				throw "assert";
		}
				
	}




	static function makeOverlayType(t:Type, e:Expr, pack:Array<String>, name:String, overlayPack:Array<String>, overlayName:String, requireAll : Bool):Type
	{
		var td = baseTypeDef(pack, name, overlayPack, overlayName);
		function switchType(t1) return switch [t1,e.expr] 
		{
			case [TInst(t,_), EObjectDecl(fields)]:
				makeOverlaySettingsFromFields(e.pos, fields, t.get().fields.get(), pack, name, name, overlayPack, overlayName, requireAll);
			case [TLazy(f),_]: switchType(f());
			case _:
				throw "Invalid";
		}

		var fields = switchType(t);
		td.fields = td.fields.concat(fields);

		var clName = overlayPack.join(".") + (if (overlayPack.length > 0) "." else "") + overlayName;

		

		Context.defineType(td);

		return Context.getType(clName);
	}

	public static function makeOverlaySettingsFromFields (pos:Position, fields:Array<{ field:String, expr:Expr}>, clFields:Array<ClassField>, pack:Array<String>, name:String, rootName:String, overlayPack:Array<String>, overlayName:String, requireAll:Bool):Array<Field> 
	{


		var f1Fields = clFields;

		var newFields:Array<Field> = [];

		var fieldsToCheck = f1Fields.map(function (cf) return cf.name);



		var fieldsToCheck = f1Fields.filter(function (cf) return cf.isPublic).map(function (cf) return cf.name);

		//trace(fieldsToCheck);
		//trace(fields.map(function (x) return x.field));

		if (requireAll && fieldsToCheck.length > fields.length) {
			var fieldsStrings = fields.map(function (x) return x.field);
			var missings = fieldsToCheck.filter(function (x) return !Lambda.has(fieldsStrings, x));

			Context.warning("ERROR: Overlay Settings " + overlayPack.join(".") + "." + overlayName + " requires all fields of " + pack.join(".") + "." +  name + "\nWarning: ERROR: Missing Fields: '" + missings.join("','") + "'", pos);
		}

		for (f1 in f1Fields) {
			var found = false;
			for (f2 in fields) {
				var valid = false;
				for (f1 in f1Fields) {
					if (f2.field == f1.name) {
						valid = true;
					}
				}
				if (!valid) {
					trace(fieldsToCheck);
					
					Context.warning("Overlay Settings " + overlayPack.join(".") + "." + overlayName + " has no field '" + f2.field + "' required by " + pack.join(".") + "." + name, pos);
					//throw "BaseConfiguration has no field " + f2.field;
				}

				if (f2.field == f1.name) {
					
					found = true;

					switch [f1.kind, f2.expr.expr] {
						case [FVar(_,_),EObjectDecl(fields)]:
							
							function switchType (t1) {
								switch (t1) {
									case TInst(t,_):
										var clFields = t.get().fields.get();
										var subName = name + f1.name.charAt(0).toUpperCase() + f1.name.substr(1);
										var subOverlayName = overlayName + f1.name.charAt(0).toUpperCase() + f1.name.substr(1);
										var td = subTypeDef(pack, subName,overlayPack, subOverlayName,rootName);

										var fields = makeOverlaySettingsFromFields(f2.expr.pos, fields, clFields, pack, subName, rootName, overlayPack, subOverlayName, requireAll);



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
								
								switch [t1, f2.expr.expr] {
									case [TLazy(f),_]: switchType(f());
									case [TFun(args,_), EFunction(_,fun)] if (args.length == fun.args.length):
										var fields:Array<Field> = [
											{
												name : f1.name,
												access : [AOverride, APublic],
												kind : FFun(fun),
												pos : f2.expr.pos
											}
										];
										newFields = newFields.concat(fields);

									case [TFun(_,_), EFunction(_)]: 
										throw "invalid";
									case [TFun([],_), x]:
										var funExpr = macro function () return ${f2.expr};
										var fun = switch (funExpr.expr) {
											case EFunction(_,f): f;
											case _: throw "invalid";
										}
										var fields:Array<Field> = [
											{
												name : f1.name,
												access : [AOverride, APublic],
												kind : FFun(fun),
												pos : f2.expr.pos
											}
										];
										newFields = newFields.concat(fields);
									case [a,b]:
										trace(a);
										trace(b); 

										//throw "invalid";

								}
								
							}
							switchType(f1.type);
						
							//throw "invalid";
					}
				}
			}

		}
		

		return newFields;
		
	}



}

#end