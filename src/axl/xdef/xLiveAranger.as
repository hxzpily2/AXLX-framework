/**
 *
 * AXLX Framework
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef
{
	import flash.events.MouseEvent;
	
	import axl.utils.LiveAranger;
	import axl.xdef.interfaces.ixDef;
	import axl.xdef.types.xSprite;
	
	public class xLiveAranger extends LiveAranger
	{
		private var lockUnderMouseEvents:Boolean;
		private var supportedProperties:Object =
			{
				x : 0,
				y : 0,
				z : 0,
				rotation:0,
				rotationX:0,
				rotationY:0,
				rotationZ:0,
				width:0,
				height:0,
				scaleX:1,
				scaleY:1
			}
			
		public function xLiveAranger()
		{
			super();
		}
		
		private function finishMovement():void
		{
			var v:ixDef = selector.target as ixDef;
			if(v == null)
				return;
			for(var s:String in supportedProperties)
			{
				if(v is xSprite && (s=='width' || s=='height'))
					continue;
				var n:Number = v[s];
				var d:Number = supportedProperties[s];
				if(n!=d)
					v.def.@[s] = n;
			}
		}
		
		override protected function mu(e:MouseEvent):void
		{
			finishMovement();
			super.mu(e);
			
		}
		
	}
}