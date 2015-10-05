package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import axl.utils.U;
	
	
	public class xButton extends xSprite
	{
		public static var defaultOver:String="upstate.alpha:[0.88,1]";
		public static var defaultDisabled:String="alpha:[0.66,1]";
		
		private var isEnabled:Boolean=true;
		private var texture:DisplayObject;
		
		public var intervalValue:int=0;
		public var intervalDelay:int = 0;
		
		private var userClickHandler:Function;
		private var eventClick:Event = new Event("clickButton",true);
		private var isRotated:Boolean;
		
		private var trigerUrl:URLRequest;
		private var trigerEvent:Event;
		private var trigerExt:Array;
		private var trigerUrlWindow:String;
		private var isDown:Boolean;
		private var delayID:uint;
		private var intervalID:uint;
		
		private var actions:Vector.<xAction> = new Vector.<xAction>();
		private var overTarget:Object;
		private var overKey:String;
		private var overVals:Object;
		private var disabledKey:String;
		private var disabledTarget:Object;
		private var disabledVals:Object;
		private var sdisabled:String;
		private var sover:String; 
		
		public var externalExecution:Boolean;
		
		
		public function xButton(definition:XML=null,xroot:xRoot=null)
		{
			super(definition);
			enabled = isEnabled;
		}
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			if(numChildren < 1)
				texture = child;
			return super.addChild(child);
		}
		//-- internal
		override public function set meta(v:Object):void
		{
			super.meta = v;
			if(meta is String)
				return
			if(meta.hasOwnProperty('url'))
			{
				if(meta.url is Array)
				{
					trigerUrl =  new URLRequest(meta.url[0]);
					trigerUrlWindow = meta.url[1];
				}
				else
					trigerUrl = new URLRequest(meta.url);
			}
			if(meta.hasOwnProperty('event'))
				trigerEvent  = new Event(meta.event,true);
			if(meta.hasOwnProperty('js'))
				trigerExt = meta.js;
			if(meta.hasOwnProperty('action'))
			{
				var a:Object = meta.action;
				var b:Array = (a is Array) ? a as Array : [a];
				for(var i:int = 0, j:int = b.length; i<j; i++)
					actions[i] = new xAction(b[i],xroot,this);
			}
		}
		
		private function checkProperties():void
		{
			if(overTarget == null)
				over = defaultOver;
			if(disabledTarget ==null)
				disabled = defaultDisabled;
		}
		
		//--click mechanic
		protected function mouseDown(e:MouseEvent):void
		{
			isDown = true;			
			U.STG.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			U.STG.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if(intervalValue > 0)
				delayID = setTimeout(repeatEvent, intervalDelay);
			
			function repeatEvent():void
			{
				if(isDown)
					intervalID = setInterval(mouseClick, intervalValue,e);
				else
					clearIntervals();
			}
		}
		
		protected function mouseClick(e:MouseEvent):void
		{
			this.dispatchEvent(eventClick);
			if(userClickHandler != null) 
			{
				if(userClickHandler.length > 0)
					userClickHandler(e);
				else
					userClickHandler();
			}
			if(!externalExecution)
				execute(e);
		}
		
		public function execute(e:MouseEvent=null):void
		{
			if(trigerUrl)
				navigateToURL(trigerUrl, trigerUrlWindow);
			if(trigerEvent != null)
				this.dispatchEvent(this.trigerEvent);
			if(this.trigerExt && ExternalInterface.available)
				ExternalInterface.call.apply(null, trigerExt);
			for(var i:int = 0, j:int = actions.length; i<j; i++)
				actions[i].execute();
		}
		
		protected function hover(e:MouseEvent):void
		{
			if(!isEnabled)
				return;
			checkProperties();
			var val:int = (e.type == MouseEvent.ROLL_OVER) ? 0 : 1;
			if(overTarget[overKey] is Function)
				overTarget[overKey].apply(null, overVals[val]);
			else
				overTarget[overKey] = overVals[val];
		}
		// --- --- PUBLIC API --- --- //
		public function setEnabled(v:Boolean):void { enabled =v }
		public function get enabled():Boolean {	return isEnabled }
		public function set enabled(v:Boolean):void
		{
			//if(isEnabled == v) return;
			isEnabled = v;
			checkProperties();
			if(!isEnabled)
			{
				U.STG.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			}
			var f:String = isEnabled ? 'addEventListener' : 'removeEventListener';
			this[f](MouseEvent.MOUSE_DOWN, mouseDown);
			this[f](MouseEvent.CLICK, mouseClick);
			this[f](MouseEvent.ROLL_OVER, hover);
			this[f](MouseEvent.ROLL_OUT, hover);
			
			buttonMode = isEnabled;
			useHandCursor = isEnabled;
			disabledTarget[disabledKey] = this.disabledVals[isEnabled ? 1 : 0];
		}
		
		
		protected function mouseUp(e:MouseEvent):void { mouseMove(e) }
		protected function mouseMove(e:MouseEvent):void
		{
			if(isDown && !e.buttonDown)
				touchEnd();
		}
		
		private function touchEnd():void
		{
			isDown = false;
			U.STG.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			U.STG.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			clearIntervals();
		}
		
		private function clearIntervals():void
		{
			flash.utils.clearInterval(intervalID);
			flash.utils.clearTimeout(delayID);
		}
		
		/** impulse over event*/
		public function get onClick():Function { return userClickHandler }
		public function set onClick(v:Function):void { userClickHandler = v	}
		
		public function get over():String { return sover }
		public function set over(v:String):void
		{
			sover = v;
			overKey = v.substring(0, v.lastIndexOf(':'));
			var val:String = v.substring(v.lastIndexOf(':')+1);
			
			var keys:Array = overKey.split('.');
			overKey = keys.pop();
			overTarget = this;
			while(keys.length)
				overTarget = overTarget[keys.shift()];
			overVals = JSON.parse(val);
		}
		public function get disabled():String { return sdisabled}
		public function set disabled(v:String):void
		{
			sdisabled = v;
			disabledKey = v.substring(0, v.lastIndexOf(':'));
			var val:String = v.substring(v.lastIndexOf(':')+1);
			
			var keys:Array = disabledKey.split('.');
			disabledKey = keys.pop();
			disabledTarget = this;
			while(keys.length)
				disabledTarget = disabledTarget[keys.shift()];
			disabledVals = JSON.parse(val);
		}
		
		public function get upstate():DisplayObject { return texture }
		public function set upstate(v:DisplayObject):void
		{
			if(texture != null && contains(texture) && texture != v)
				this.removeChild(texture);
			texture = v;
			if(upstate !=null)
				this.addChild(texture);
			rotated = rotated;
		}
		
		public function get rotated():Boolean { return isRotated }
		public function set rotated(v:Boolean):void
		{
			isRotated = v;
			if(!texture)
				return;
			if(isRotated)
			{
				texture.rotation = 180;
				texture.x = texture.width;
				texture.y = texture.height;
			}
			else
			{
				texture.rotation = 0;
				texture.x = 0;
				texture.y =0;
			}
		}
	}
}