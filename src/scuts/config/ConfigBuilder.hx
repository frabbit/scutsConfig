
package scuts.config;


import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

class ConfigBuilder
{
	
	macro public static function asSettings (e:Expr, pack:Array<String>, name:String):Type 
	{
		var className = name;


		var typeDefinition = switch (e.expr) 
		{
			case EObjectDecl(fields):
				
				makeSettingsFromFields(fields, pack, name, name, e);
			case _:
				throw "Invalid Settings, should be an anonymous object";
		}
		
		Context.defineType(typeDefinition);
		
		var t = Context.getType(pack.join(".") + (if (pack.length > 0) "." else "") + name);
		
		
		return t;

	}

	#if macro

	public static function makeSettingsFromFields (fields:Array<{ field:String, expr:Expr}>, pack:Array<String>, name:String, rootName:String, expr:Expr):TypeDefinition
	{

		
		var classFields = fields.map(anonToClassField.bind(_, pack, name, rootName));


		

		var baseClass:TypeDefinition = if (rootName == name) {
			m1(pack, name, expr);
		} else {
			m2(pack, name, rootName, expr);
		}
		

		


		for (f in classFields) {
			baseClass.fields = baseClass.fields.concat(f);
		}

		

		return baseClass;

	}

	static function anonToClassField (f:{field:String, expr:Expr}, pack:Array<String>, name, rootName, ?doc : String = null):Array<Field> {
		return switch (f.expr.expr) {
			case EMeta(m, e) if (m.name == ":doc"):
			
				var docStr = switch(m.params[0].expr) {
					case EConst(CString(s)): s;
					case _: null;
				}
				return anonToClassField({field:f.field, expr:e}, pack, name, rootName, docStr);
			case EFunction(x,fun):
				[{
					name : f.field,
					doc : doc,
					access : [APublic],
					kind : FFun(fun),
					pos : f.expr.pos
				}];
			case EObjectDecl(subFields):
				// create settings type and make a setter which returns a new Instance of this kind lazy create.
				var subTypeName = name + f.field.charAt(0).toUpperCase() + f.field.substr(1);
				var subTypeDef = makeSettingsFromFields(subFields, pack, subTypeName, rootName, f.expr);
				Context.defineType(subTypeDef);
				Context.onTypeNotFound(function (t) {
					return if (t == subTypeName) {
						subTypeDef;
					} else null;
				});

				

				var fieldName = f.field;


				var fields = m3(pack, fieldName, subTypeName, doc, f.expr);

				
				fields;

			case e:
				// regular field, just add a lazy setter
				var fieldName = "_cfg_" + f.field;
				var newFun = 
					macro function () {
						return ${f.expr};
					};
				var fun = switch (newFun.expr) {
					case EFunction(_,f):f;
					case _ : null;
				}
				
				[
					{
						doc : doc,
						name : f.field,
						access : [APublic],
						kind : FFun(fun),
						pos : f.expr.pos
					}

				];

				



		}
	}
	
	
	public static function m3 (pack:Array<String>, fieldName:String, subTypeName:String, doc:Null<String>, expr:Expr):Array<Field> 
	{
		
		var newFun = 
			macro function () {
				if ($i{fieldName} == null) {
					$i{fieldName} = new $subTypeName(null, this.context);
					
				}
				return $i{fieldName};
			};
		var f = switch (newFun.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			{
				doc : doc,
				name : fieldName,
				access : [APublic],
				kind : FieldType.FProp("get", "null", TPath({ name : subTypeName, pack : pack, params : []})),
				meta :  [{ name : ":isVar", params:[], pos : Context.currentPos()}],
				pos : expr.pos
			},
			{
				name : "get_" + fieldName,
				access : [APrivate],
				kind : FFun(f),
				pos : expr.pos
			}
		];

		return fields;
		
	}

	public static function m1 (pack, name,e:Expr):TypeDefinition 
	{
		var ct = TPath({pack:[],params:[],name:name});
		var newFun = 
			macro function (parent:$ct) {
				this.context = this;
				this.parent = parent;
			};
		var f = switch (newFun.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			{
				name : "parent",
				access : [APrivate],
				kind : FieldType.FVar(TPath({ name : name, pack : pack, params : []})),
				pos : e.pos
			},
			{
				name : "context",
				access : [APrivate],
				kind : FieldType.FVar(TPath({ name : name, pack : pack, params : []})),
				pos : e.pos
			},
			{
				name : "new",
				access : [APublic],
				kind : FFun(f),
				pos : e.pos
			}
		];

		return {
			pack :pack,
			name : name,
			pos : e.pos,
			meta : [],
			params : [],
			isExtern : false,
			kind : TDClass(),
			fields : fields
		}
		
	}

	public static function m2 (pack:Array<String>, name:String, rootName:String, expr:Expr):TypeDefinition 
	{

		var ct = TPath({pack:[],params:[],name:name});

		var newFun = 
			macro function (parent:$ct, context) {
				this.context = context;
				this.parent = parent;
			};
		var f = switch (newFun.expr) {
			case EFunction(_,f):f;
			case _ : null;
		}

		var fields:Array<Field> = [
			{
				name : "parent",
				access : [APrivate],
				kind : FieldType.FVar(TPath({ name : name, pack : pack, params : []})),
				pos : expr.pos
			},
			{
				name : "context",
				access : [APrivate],
				kind : FieldType.FVar(TPath({ name : rootName, pack : pack, params : []})),
				pos : expr.pos
			},
			{
				name : "new",
				access : [APublic],
				kind : FFun(f),
				pos : expr.pos
			}
		];

		return {
			pack :pack,
			name : name,
			pos : expr.pos,
			meta : [],
			params : [],
			isExtern : false,
			kind : TDClass(),
			fields : fields
		}
		
	}
	#end

	/*
	public static function m1 ():TypeDefinition 
	{
		return (macro class X {
			var context : Z;
			public function new (parent:X) {
				this.context = this;
			}

		});
	}
	public static function m2 ():TypeDefinition 
	{
		return (macro class X {
			var context : Z;
			public function new (parent:X, context) {
				this.context = context;
			}

		});
	}
	*/
	/*
	public static function m3 (fieldName:String, subTypeName:String):TypeDefinition 
	{
		return (macro class Z{
			@:isVar public var x(get, null):X;
			public function get_x () {
				if ($i{fieldName} == null) {
					$i{fieldName} = new $subTypeName(null, this);
					
				}
				return $i{fieldName};
			}
		});
	}
	*/
	


	
}

