package axl.xdef
{
	import com.screens.Div;
	import com.screens.Masked;
	import com.screens.ScrollBar;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.text.TextField;
	import flash.utils.getDefinitionByName;
	
	import axl.ui.Carusele;
	import axl.ui.MaskedScrollable;
	import axl.utils.AO;
	import axl.utils.Ldr;
	import axl.xdef.interfaces.ixDisplay;
	import axl.xdef.types.xButton;
	import axl.xdef.types.xSprite;
	import axl.xdef.types.xText;

	public class XSupport
	{
		public static var defaultFont:String;
		private static var additionQueue:Vector.<Function> = new Vector.<Function>();
		private static var afterQueueVec:Vector.<Function> = new Vector.<Function>();;
		public static function applyAttributes(def:XML, target:Object):Object
		{
			if(def == null)
				return target; 
			var attribs:XMLList = def.attributes();
			var al:int = attribs.length();
			var val:*;
			var key:String;
			for(var i:int = 0; i < al; i++)
			{
				key = attribs[i].name();
				val = attribs[i].valueOf();
				val = valueReadyTypeCoversion(val);
				if(target.hasOwnProperty(key))
					target[key] = val;
			}
			if(def.hasOwnProperty('@meta') && target.hasOwnProperty('meta'))
			{
				try{target.meta = JSON.parse(String(target.meta))}
				catch(e:Error) {throw new Error("Invalid json for element " + target + " of definition: " + def.toXMLString()); }
			}
			return target;
		}
		
		public static function animByName(target:ixDisplay, animName:String, onComplete:Function=null, killCurrent:Boolean=true,reset:Boolean=false):void
		{
			if(reset)
				target.reset();
			else if(killCurrent);
				AO.killOff(target);
			if(target.meta.hasOwnProperty(animName))
			{
				var a:Array = target.meta[animName];
				var ag:Array = [];
				if(!(a[0] is Array))
					ag[0] =  a;
				else
					ag = a;
				var atocomplete:uint = ag.length;
				for(var i:int = 0; i < ag.length; i++)
				{
					var g:Array = [target].concat(ag[i]);
					g[3] = acomplete;
					AO.animate.apply(null, g);
				}
			}
			else if(onComplete != null)
				onComplete();
			function acomplete():void
			{
				if(--atocomplete < 1 && onComplete != null)
					onComplete();
				target.dispatchEvent(target.eventAnimationComplete);
			}
		}
		public static function valueReadyTypeCoversion(val:String):*
		{
			switch(val)
			{
				case 'null': return null;
				case 'true': return true;
				case 'false': return false;
			}
			return val;
		}
		
		public static function filtersFromDef(xml:XML):Array
		{
			var fl:XMLList = xml.filter;
			var len:int = fl.length();
			var ar:Array = [];
			for(var i:int = 0; i < len; i++)
				ar[i] = filterFromDef(fl[i]);
			trace("RETURNING RRAY OF FILTERS", ar);
			return ar.length > 0 ? ar : null;
		}
		public static function filterFromDef(xml:XML):BitmapFilter
		{
			trace("FILTER FROM DEF", xml.toXMLString());
			var type:String = 'flash.filters.'+String(xml.@type);
			var Fclass:Class;
			try { Fclass = flash.utils.getDefinitionByName(type) as Class} catch (e:Error) {}
			if(Fclass == null)
				throw new Error("Invalid filter class in definition: " + xml.toXMLString());
			var filter:BitmapFilter = new Fclass();
			applyAttributes(xml, filter);
			trace("FI:TER READY", filter );
			return filter;
		}
		
		public static function getTextFieldFromDef(def:XML):TextField
		{
			if(def == null)
				return null;
			var tf:xText = new  xText(def);
			return tf;
		}
		
		public static function getButtonFromDef(xml:XML, handler:Function,dynamicSourceLoad:Boolean=true):xButton
		{
			var btn:xButton = new xButton(xml);
				btn.onClick = handler;
			if(dynamicSourceLoad)
				checkSource(xml, buttonCallback,true);
			else 
				return buttonCallback();
			function buttonCallback():xButton
			{
				btn.upstate = Ldr.getBitmapCopy(String(xml.@src));
				return btn;
			}
			return btn;
		}
		
		public static function getImageFromDef(xml:XML, dynamicSourceLoad:Boolean=true):xSprite
		{
			var spr:xSprite = new xSprite();
			if(dynamicSourceLoad)
				checkSource(xml, imageCallback,true);
			else 
				return imageCallback();
			function imageCallback():xSprite
			{
				spr.addChild(Ldr.getBitmapCopy(String(xml.@src)));
				spr.def = xml;
				return spr;
			}
			return spr;
		}	
		public static function getSwfFromDef(xml:XML, dynamicSourceLoad:Boolean=true):xSprite
		{
			var spr:xSprite = new xSprite();
			if(dynamicSourceLoad)
				checkSource(xml, swfCallback,true);
			else 
				return swfCallback();
			function swfCallback():xSprite
			{
				spr.addChild(Ldr.getAny(String(xml.@src)) as DisplayObject);
				pushReadyTypes(xml, spr);
				spr.def = xml;
				return spr;
			}
			return spr;
		}
		
		public static function getMaskedFromDef(xml:XML):MaskedScrollable
		{
			var msk:MaskedScrollable = new MaskedScrollable();
			pushReadyTypes(xml, msk.container);
			applyAttributes(xml, msk);
			return msk;
		}
		
		public static function getCaruselFromDef(xml:XML):Object
		{
			var carusel:Carusele = new Carusele();
			XSupport.pushReadyTypes(xml, carusel, 'addToRail');
			XSupport.applyAttributes(xml, carusel);
			carusel.movementBit(0);
			return carusel;
		}
		
		private static function unknownTypeFromDef(xml:XML):Object
		{
			var obj:Object = Ldr.getAny(String(xml.@src));
			if(obj != null)
				XSupport.applyAttributes(xml, obj);
			return obj;
		}
		
		public static function drawFromDef(def:XML, drawable:Sprite=null):DisplayObject
		{
			
			if(drawable == null)
				drawable= new Sprite();
			var commands:XMLList = def.command;
			var command:XML;
			var cl:int = commands.length();
			var vals:Array
			var directive:String;
			for(var c:int = 0; c < cl; c++)
			{
				command = commands[c];
				directive = command.toString();
				var attribs:XMLList = command.attributes();
				var al:int = attribs.length();
				var val:String;
				var key:String;
				vals = [];
				for(var i:int = 0; i < al; i++)
				{
					key = attribs[i].name();
					val = attribs[i].valueOf();
					vals[i] = val;
				}
				drawable.graphics[directive].apply(null, vals);
				
			}
			applyAttributes(def, drawable);
			return drawable;
		}
		
		public static function pushReadyTypes(def:XML, container:DisplayObjectContainer, command:String='addChildAt'):void
		{
			if(def == null)
				return;
			var celements:XMLList = def.children();
			var type:String;
			var i:int = -1;
			var numC:int = celements.children().length();
			for each(var xml:XML in celements)
				getReadyType(xml, readyTypeCallback,true, ++i);
			function readyTypeCallback(v:Object, index:int):void
			{
				if(v != null)
				{
					if(v is Array)
					{
						trace("PUSHING FILTER TO", container, container.filters is Array);
						container.filters = v as Array;
						trace("container filters", container.filters);
						return
					}
					if(command == 'addChildAt')
					{
						if(index < container.numChildren-1)
							container[command](v, index);
						else
							container['addChild'](v);
					}
					else if(command == 'addToRail')
						container[command](v,false);
					else
						container[command](v);
				}
			}
		}
		
		private static function checkSource(xml:XML, callBack:Function, dynamicLoad:Boolean=true):void
		{
			if(xml.hasOwnProperty('@src'))
			{
				var source:String = String(xml.@src);
				var inLib:Object = Ldr.getAny(source);
				if(inLib is Bitmap)
					inLib = Ldr.getBitmapCopy(source);
				if(inLib != null)
					callBack(xml);
				else if(dynamicLoad)
					Ldr.load(source, function():void{callBack(xml)});
				else
					callBack(xml);
			}
			else
				callBack(xml);
		}
		
		public static function getReadyType(xml:XML, callBack:Function, dynamicLoad:Boolean=true,callBack2argument:Object=null):void
		{
			if(xml == null)
				throw new Error("Undefined XML definition");
			//U.log("REQUEST READY TYPE", xml.name(), (xml.hasOwnProperty('@name')) ? xml.@name : 'noname', 'queue state:', additionQueue.length);
			proxyQueue(proceed);
			function proceed():void
			{
				//U.log("...PRoCEED", xml.name(), (xml.hasOwnProperty('@name')) ? xml.@name : 'noname', 'queue state:', additionQueue.length);
				var type:String = xml.name();
				var obj:Object;
				if(dynamicLoad)
					checkSource(xml, readyTypeCallback, true);
				else
					readyTypeCallback();
				function readyTypeCallback():Object
				{
					trace('readyTypeCallback', type, xml.@name);
					switch(type)
					{
						case 'txt': obj = getTextFieldFromDef(xml);	break;
						case 'msk': obj = getMaskedFromDef(xml); break;
						case 'masked': obj = new Masked(xml); break;
						case 'img': obj = getImageFromDef(xml,false); break;
						case 'btn': obj = getButtonFromDef(xml,null,false); break;
						case 'div': obj = new Div(xml); break;
						case 'swf': obj = getSwfFromDef(xml); break;
						case 'carousel' : obj = getCaruselFromDef(xml); break;
						case 'scrollBar': obj = new ScrollBar(xml); break;
						case 'filters': obj = filtersFromDef(xml); break;
						default : obj = unknownTypeFromDef(xml); break;
					}
					if(callBack2argument != null)
						callBack(obj, callBack2argument);
					else
						callBack(obj);
					additionQueue.shift();
					if(additionQueue.length > 0)
						additionQueue[0]();
					else
					{
						while(afterQueueVec.length > 0)
							afterQueueVec.shift()();
					}
				}
			}
		}
		
		
		public static function proxyQueue(call:Function):void
		{
			additionQueue.push(call);
			if(additionQueue.length == 1)
				call();
		}
		
		public static function afterQueue(callback:Function):void
		{
			if(callback == null)
				return;
			if(additionQueue.length < 1)
				callback();	
			else
				afterQueueVec.push(callback);
		}
	}
}