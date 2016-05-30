/**
 *
 * AXLX Framework
 * Copyright 2014-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	
	import axl.ui.controllers.BoundBox;

	/** Class instantiated from  &lt;msk/&gt; node, extends xSprite by adding three functionalites:
	 * <ul><li>provides ready to use and already assigned, rectangular mask - controllable  by properties <i>visibleWidth,
	 * visibleHeight, visibleX, visibleY</i></li>
	 * <li>provides <code>controller</code> property - an instance of BoundBox class, which allows to scroll, drag and move
	 * masked contents within masked area</li><li>exposes ability to make bi-directional connections with any other BoundBox controllers,
	 * e.g. members of <code>xScroll</code> (&lt;scrollBar/&gt;) instance </li></ul>*/
	public class xMasked extends xSprite
	{
		private var controllers:Vector.<BoundBox>;
		private var ctrl:BoundBox;
		private var xscrollBar:xScroll;
		
		private var container:xSprite;
		private var shapeMask:Shape;
		private var vX:Number=0;
		private var vY:Number=0;
		private var vWid:Number=1;
		private var vHeight:Number=1;
		
		/** Determines scroll efficiency default 1. For container containing textfields optimal value is 15*/
		public var deltaMultiplier:Number=1;
		/** Deterimines if masked content movement can be triggered by mouse wheel events.  @see #deltaMultiplier */
		public var wheelScrollAllowed:Boolean = false;
		
		/** Class instantiated from  &lt;msk/&gt; node. Easy masking and movable/scorllable container.
		 * @param definition - xml definition
		 * @param xroot - reference to parent xRoot object
		 * @see axl.xdef.types.xObject
		 * @see axl.xdef.interfaces.ixDef#def
		 * @see axl.xdef.interfaces.ixDef#xroot
		 * @see axl.xdef.XSupport#getReadyType2() */
		public function xMasked(definiton:XML=null,xroot:xRoot=null)
		{
			ctrl = new BoundBox();
			controllers = new Vector.<BoundBox>();
			shapeMask = new Shape();
			container = new xSprite(null,xroot);
			container.name = "maskContainerOf_" + String((definiton != null) ? definiton.@name : "null");
			super(definiton,xroot);
			super.addChild(container);
			super.addChild(shapeMask);
			
			redrawMask();
			ctrl.bound = shapeMask;
			ctrl.box = container;
			addListeners();
		}
		// -------------------OVERRIDEN METHODS  --------------- //
		override public function addChild(child:DisplayObject):DisplayObject
		{
			var v:xScroll = child as xScroll;
			if(v)
			{
				scrollBar = v;
				super.addChild(child);
			}
			else
				container.addChild(child);
			return child;
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			var v:xScroll = child as xScroll;
			if(v)
			{
				scrollBar = v;
				super.addChildAt(child, index);
			}
			else
				container.addChildAt(child,index);
			return child
		}
		
		private function addListeners():void 
		{
			ctrl.onChange = onControllerChange;
			container.addEventListener(MouseEvent.MOUSE_WHEEL, wheelEvent) 
		}
		// -------------------OVERRIDEN METHODS  --------------- //
		// ------------------- CONTROLLERS LOGIC --------------- //
		
		/** Allows to make bi-directional connection between scrollBar instance and masked container.
		 * Bi-directional means that both scroll bar can update container and container can update scrollbar. */
		public function get scrollBar():xScroll	{ return xscrollBar }
		public function set scrollBar(v:xScroll):void
		{
			xscrollBar = v;
			if(!xscrollBar) return;
			if(xscrollBar.controller == null)
				throw new Error("scrollBar element needs elements named 'rail' and 'train'");
			addController(v.controller);
		}
		/** Allows to make bi-directional connection between controller of masked container of this instance and  any other
		 * controller. Bi-directional means both scroll bar can update container and container can update scrollbar. 
		 * Controllers orientation have to match to receive updates stream. @see axl.ui.controllers.BoundBox */
		public function addController(v:BoundBox):void
		{
			if(v && controllers.indexOf(v) < 0)
			{
				v.onChange = onSubControllerChange;
				controllers.push(v);
			}
		}
		/** Removes contoller from initiators/receivers list and terminates connection between them (onChange null asignnemt)
		 * @see #addController()*/
		public function removeController(v:BoundBox):void
		{
			var i:int = controllers.indexOf(v);
			if(i < 0) return
			controllers.splice(i,1)[0].onChange = null;
		}
		private function onControllerChange(e:Object=null):void
		{
			var initiator:BoundBox = e as BoundBox;
			if(!initiator) return;
			for(var i:int = 0, j:int = controllers.length,receiver:BoundBox; i<j;i++)
			{
				receiver = controllers[i];
				if(receiver == initiator) continue;
				updateReceiver(initiator, receiver);
			}
		}
		
		private function onSubControllerChange(e:Object=null):void
		{
			if(e==ctrl || !e) 
				return;
			updateReceiver(e as BoundBox,ctrl);
		}
		
		private function updateReceiver(initiator:BoundBox, receiver:BoundBox):void
		{
			if(initiator.horizontal && initiator.vertical)
			{
				if(receiver.horizontal && receiver.vertical)
					receiver.percentageCommon(1-initiator.percentageHorizontal, 1-initiator.percentageVertical);
				else if(receiver.horizontal)
					receiver.setPercentageHorizontal(1-initiator.percentageHorizontal);
				else if(receiver.vertical)
					receiver.setPercentageVertical(1-initiator.percentageVertical);
			}
			else if(initiator.horizontal && receiver.horizontal)
				receiver.setPercentageHorizontal(1-initiator.percentageHorizontal);
			else if(initiator.vertical && receiver.vertical)
				receiver.setPercentageVertical(1-initiator.percentageVertical);
		}
		
		/** Receives wheel events and passes delta * deltaMultipy values to controller. */
		protected function wheelEvent(e:MouseEvent):void 
		{
			if(!wheelScrollAllowed || e.delta==0)
				return;
			if(ctrl.vertical)
				ctrl.movementVer(e.delta * deltaMultiplier,false,ctrl);
			else if(ctrl.horizontal)
				ctrl.movementHor(e.delta * deltaMultiplier,false,ctrl);
		}
		// ----------------- CONTROLLERS LOGIC --------------//
		// ----------------- INTERNAL  --------------//
		private function redrawMask():void
		{
			shapeMask.graphics.clear();
			shapeMask.graphics.beginFill(0);
			shapeMask.graphics.drawRect(0,0,visibleWidth, visibleHeight);
			shapeMask.x = vX;
			shapeMask.y = vY;
			container.mask =shapeMask;
			controller.refresh(true);
		}
		// ----------------- INTERNAL  --------------//
		// ----------------- PUBLIC API  --------------//
		/** Height of internal mask */
		public function get visibleHeight():Number { return vHeight }
		public function set visibleHeight(value:Number):void
		{
			vHeight = value;
			redrawMask();
		}
		/** Width of internal mask */
		public function get visibleWidth():Number { return vWid }
		public function set visibleWidth(value:Number):void
		{
			vWid = value;
			redrawMask();
		}
		/** Horizintal offset of internal mask */
		public function get visibleX():Number { return vX }
		public function set visibleX(v:Number):void
		{
			vX = v;
			redrawMask();
		}
		/** Vertical offset of internal mask */
		public function get visibleY():Number { return vY }
		public function set visibleY(v:Number):void
		{
			vY = v;
			redrawMask();
		}
		
		/** Returns controller @see axl.ui.controllers.BoundBox */
		public function get controller():BoundBox { return ctrl }
		
	}
}