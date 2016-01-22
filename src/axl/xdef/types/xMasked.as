/**
 *
 * AXLX Framework
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import axl.ui.controllers.BoundBox;
	import axl.utils.U;
	import axl.xdef.interfaces.ixDisplay;

	public class xMasked extends xSprite implements ixDisplay
	{
		public var scrollBar:xScroll;
		
		private var vWid:Number=1;
		private var vHeight:Number=1;
		private var shapeMask:Shape;
		private var maskObject:DisplayObject;
		
		private var fakeRect:Rectangle = new Rectangle();
		private var eventChange:Event = new Event(Event.CHANGE);
		private var ctrl:BoundBox;
		private var deltaMultiply:Number=1;
		
		public var container:xSprite;
		public var wheelScrollAllowed:Boolean = true;
		private var vX:Number=0;
		private var vY:Number=0;
		
		public function xMasked(definiton:XML=null,xroot:xRoot=null)
		{
			ctrl = new BoundBox();
			shapeMask = new Shape();
			container = new xSprite(null,xroot);
			container.name = "maskContainerOf_" + String((definiton != null) ? definiton.@name : "null");
			//container.mask = shapeMask;
			super(definiton,xroot);
			super.addChild(container);
			super.addChild(shapeMask);
			
			redrawMask();
			ctrl.bound = shapeMask;
			ctrl.box = container;
			maskObject = shapeMask;
			addListeners();

		}
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			if(child is xScroll)
			{
				scrollBar = child as xScroll;
				if(scrollBar.controller == null)
					throw new Error("scrollBar element needs elements named 'rail' and 'train'");
				scrollBar.controller.addEventListener(Event.CHANGE, scrollBarMovement);
				super.addChild(child);
			}
			else
				container.addChild(child);
			return child;
		}
		
		override protected function elementAdded(e:Event):void
		{
			if(!isNaN(distributeHorizontal))
				U.distribute(container,distributeHorizontal,true);
			if(!isNaN(distributeVertical))
				U.distribute(container,distributeVertical,false);
		}
		
		private function addListeners():void {
			ctrl.addEventListener(Event.CHANGE, maskedMovement);
			container.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent) 
		}
		
		protected function wheelEvent(e:MouseEvent):void 
		{
			if(!wheelScrollAllowed || e.delta==0)
				return;
			//U.log(this, this.name,ctrl.vertical ? 'vertical': "", ctrl.horizontal ? "horizontal" :"", 'delta:', e.delta,  'multply:', deltaMultiply, 'v:',  e.delta * deltaMultiply );
			if(ctrl.vertical)
				ctrl.movementVer(e.delta * deltaMultiply);
			else if(ctrl.horizontal)
				ctrl.movementHor(e.delta * deltaMultiply);
		}
		
		protected function scrollBarMovement(e:Event=null):void
		{
			var val:Number = (scrollBar.controller.horizontal ? scrollBar.controller.percentageHorizontal : scrollBar.controller.percentageVertical);
			ctrl.changeNotifications = false;
			ctrl.liveChanges = false;
			if(ctrl.vertical)
				ctrl.setPercentageVertical(1 - val,true)
			else if(ctrl.horizontal)
				ctrl.setPercentageHorizontal(1 -val,true);
			ctrl.changeNotifications = true;
			ctrl.liveChanges = true;
		}
		
		protected function maskedMovement(e:Event=null):void
		{
			if(scrollBar != null)
			{
				var cur:Number,newv:Number,diff:Number;
				scrollBar.controller.changeNotifications = false;
				scrollBar.controller.liveChanges = false;
				if(scrollBar.controller.horizontal)
				{
					cur = scrollBar.controller.percentageHorizontal;
					newv = 1- (ctrl.horizontal ? ctrl.percentageHorizontal : ctrl.percentageVertical);
					diff = Math.abs(newv-cur);
					if(diff > 0.001)
						scrollBar.controller.setPercentageHorizontal(newv,true)
				}
				
				if(scrollBar.controller.vertical)
				{
					cur = scrollBar.controller.percentageVertical;
					newv = 1- (ctrl.vertical ? ctrl.percentageVertical : ctrl.percentageHorizontal);
					diff = Math.abs(newv-cur);
					if(diff > 0.001)
						scrollBar.controller.setPercentageVertical(newv,true);
				}
				scrollBar.controller.changeNotifications = true;
				scrollBar.controller.liveChanges = true;
			}
		}
		
		public function refreshToScrollBar():void
		{
			scrollBarMovement();
		}
		public function refreshToContent():void
		{
			maskedMovement()
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			if(child is xScroll)
			{
				scrollBar = child as xScroll;
				if(scrollBar.controller == null)
					throw new Error("scrollBar element needs elements named 'rail' and 'train'");
				scrollBar.controller.addEventListener(Event.CHANGE, scrollBarMovement);
				super.addChildAt(child, index);
			}
			else
				container.addChildAt(child,index);
			return child
		}
		
		
		private function redrawMask():void
		{
			shapeMask.graphics.clear();
			shapeMask.graphics.beginFill(0);
			shapeMask.graphics.drawRect(0,0,visibleWidth, visibleHeight);
			shapeMask.x = vX;
			shapeMask.y = vY;
			container.mask =shapeMask;
		}
		
		// -------------------------------- PUBLIC API ---------------------------------- //
		public function get visibleHeight():Number { return vHeight }
		public function set visibleHeight(value:Number):void
		{
			vHeight = value;
			redrawMask();
		}
		
		public function get visibleWidth():Number { return vWid }
		public function set visibleWidth(value:Number):void
		{
			vWid = value;
			redrawMask();
		}
		
		public function get visibleX():Number { return vX }
		public function set visibleX(v:Number):void
		{
			vX = v;
			redrawMask();
		}
		
		public function get visibleY():Number { return vY }
		public function set visibleY(v:Number):void
		{
			vY = v;
			redrawMask();
		}
		
		public function setMask(v:DisplayObject):void
		{
			if(maskObject != null && contains(maskObject))
				removeChild(maskObject);
			if(shapeMask != null && contains(shapeMask))
				removeChild(shapeMask);
			maskObject = v;
			this.addChild(maskObject);
			container.mask = maskObject;
		}
		
		/** determines scroll efficiency default 1. Passing font size + spacing */
		public function get deltaMultiplier():Number { return deltaMultiply }
		public function set deltaMultiplier(value:Number):void	{ deltaMultiply = value }
		
		/** returns controller */
		public function get controller():BoundBox { return ctrl }
		
	}
}