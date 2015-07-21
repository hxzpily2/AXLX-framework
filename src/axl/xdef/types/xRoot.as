package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.utils.setTimeout;
	
	import axl.utils.AO;
	import axl.utils.U;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;

	/** Master class for XML DisplayList projects. Treat it as your stage */
	public class xRoot extends xSprite
	{
		public static var instance:xRoot;
		public var elements:Object = {};
		/** Master class for XML DisplayList projects. Treat it as your stage */
		public function xRoot(definition:XML=null)
		{
			super(definition);
		/*	if(instance != null)
				throw new Error("SINGLETONE EXCEPTION! " + this);*/
			instance = this;
			
		}
		// ADD - REMOVE
		public function add(v:Object,underChild:String=null,indexModificator:int=0,node:String='additions'):void
		{
			if(v is Array)
				getAdditionsByName(v as Array, gotit);
			else
				getAdditionByName(v as String, gotit)
			function gotit(d:DisplayObject):void{
				
				if(underChild != null)
					addUnderChild(d,underChild,indexModificator);
				else
					addChild(d);
			}
		}
		public function addRespective(v:Object,underChild:String=null,indexModificator:int=0,node:String='additions'):void
		{
			var o:DisplayObject = getChildByName(underChild);
			var i:int = o ? this.getChildIndex(o) : -1;
			i+=indexModificator;
			
			if(v is Array)
				getAdditionsByName(v as Array, gotit);
			else
				getAdditionByName(v as String, gotit);
			
			trace("addRespective", v, v.name, 'UNDER',  underChild, "MOD", indexModificator, "INDEX:", i);
		
			function gotit(d:DisplayObject):void{
				if(i>= this.numChildren)
					i = this.numChildren -1;
				if(i<0)
					i=0;
				if(underChild != null)
					addChildAt(d,i++);
				else
					addChild(d);
			}
		}
		
		public function addUnderChild(v:DisplayObject, chname:String,indexMod:int=0):void
		{
			var o:DisplayObject = getChildByName(chname);
			var i:int = o ? this.getChildIndex(o) : -1;
			trace("ADD UNDER CHILD", v, v.name, 'UNDER', chname, "INDEX:", i, '+ MOD', indexMod);
			if(i > -1)
			{
				i+= indexMod;
				if(i<0)
					i=0;
				if(i < this.numChildren)
					this.addChildAt(v,i);
				else
					this.addChild(v);
			}
			else this.addChild(v);
		}
		
		/** Returns first XML child of Config[node] which matches it name */
		public function getAdditionDefByName(v:String,node:String='additions'):XML
		{
			return U.CONFIG[node].*.(@name==v)[0];
		}
		/** Instantiates element from loaded config node. Instantiated / loaded / cached object
		 * is an argument for callback. 
		 * <br>All objects are being created within <code>XSupport.getReadyType</code> function. 
		 * <br>All objects are being cached within <code>XSupport.elements</code> dictionary where
		 * xml attribute <b>name</b> is key for it. 
		 * @param v - name of the object (must match any child of <code>node</code>). Objects
		 * are being looked up by <b>name</b> attribute. E.g. v= 'foo' for
		 *  <pre> < node>< div name="foo"/>< /node>  </pre> 
		 * @param callback - Function of one argument - loaded element. Function will be executed 
		 * once element is available (elements with <code>src</code> attribute may need to require loading of their contents).
		 * @param node - name of the XML tag (not an attrubute!) that is a parent for searched element to instantiate.
		 * @see axl.xdef.XSupport#getReadyType()
		 */
		public function getAdditionByName(v:String, callback:Function, node:String='additions',onError:Function=null):void
		{
			U.log('getAdditionByName', v);
			if(elements[v] != null)
			{
				U.log(v, 'already exists in "METAS" cache');
				callback(elements[v]);
				return;
			}
			
			var xml:XML = getAdditionDefByName(v,node);
			if(xml== null)
			{
				if(onError == null) 
					throw new Error(v + ' does not exist in additions node');
				else
				{
					onError();
					return;
				}
			}
			
			XSupport.getReadyType(xml, loaded);
			function loaded(dob:DisplayObject):void
			{
				elements[v] =  dob;
				callback(dob);
			}
		}
		
		/** Executes <code>getAdditionByName</code> in a loop. @see #getAdditionByName() */
		public function getAdditionsByName(v:Array, callback:Function):void
		{
			var i:int = 0, j:int = v.length;
			next();
			function next():void
			{
				if(i<j)
					getAdditionByName(v[i++], ready);
			}
			
			function ready(v:DisplayObject):void
			{
				callback(v);
				next()
			}
		}
		
		/** Removes elements from display list. Accepts arrays of display objects, their names and
		 * mixes of it. Skipps objects which are not part of the display list. */
		public function remove(...args):void
		{
			for(var i:int = 0,j:int = args.length, v:Object; i < j; i++)
			{	
				trace("XROOT REMOVE", args[i]);
				v = args[i]
				if(v is Array)
					removeElements(v as Array);
				else if(v is String)
					removeByName(v as String);
				else if(v is DisplayObject)
					removeChild(v as DisplayObject)
				else
					throw new Error("Can't remove: " + v + " - is unknow type");
			}
		}
		/** If child of name specified in argument exists - removes it. All animtions are performed
		 * based on individual class settings (xBitmap, xSprite, xText, etc)*/
		public function removeByName(v:String):void	{ removeChild(getChildByName(v)) }
		
		/**  removes array of objects from displaylist. can be actual displayObjects or their names */
		public function removeElements(args:Array):void
		{
			for(var i:int = args.length; i-->0;)
				args[i] is String ? removeByName(args[i]) : removeChild(args[i]);
		}
		
		/**  Uses registry to define child to remove. This can reach inside containers to remove specific element.
		 * The last registered element of name defined in V will be removed */
		public function removeRegistered(v:String):void
		{
			var dobj:DisplayObject = XSupport.registered(v) as DisplayObject
			if(dobj != null && dobj.parent != null)
				dobj.parent.removeChild(dobj);
		}
		/** executes <code>removeRegistered</code> in a loop */
		public function removeRegisteredGroup(v:Array):void
		{
			for(var i:int = 0; i < v.length; i++)
				removeRegistered(v[i]);
		}

		// ANIMATION UTILITIES - to comment
		public function singleAnimByMetaName(objName:String, screenName:String, onComplete:Function=null,c:ixDef=null):void
		{
			c = c || this.getChildByName(objName) as ixDef;
			U.log("singleAnimByMetaName [", screenName, '] - ', objName, c);
			if(c != null && c.meta.hasOwnProperty(screenName))
			{
				var args:Array = [c].concat(c.meta[screenName]);
				args[3] = onComplete;
				AO.animate.apply(null, args);
			}
			else
			{
				if(onComplete != null)
					setTimeout(onComplete, 5);
			}
		}
		
		public function animateAllRegisteredToScreen(screenName:String,onComplete:Function=null):void
		{
			trace("animateAllRegisteredToScreen", screenName);
			var all:int=0;
			var reg:Object = XSupport.registry;
			for(var s:String in reg)
			{
				var c:ixDef = reg[s] as ixDef;
				if(c != null && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c);
				}
			}
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
		
		public function animAllMetaToScreen(screenName:String,onComplete:Function=null):void
		{
			trace("animAllMetaToScreen", screenName);
			var all:int=0;
			for(var i:int = 0; i < this.numChildren; i++)
			{
				var c:ixDef = this.getChildAt(i) as ixDef;
				if(c != null && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c);
				}
			}
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
	}
}