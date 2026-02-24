package
{
   import Shared.AS3.Data.*;
   import Shared.AS3.Events.*;
   import Shared.AS3.ListFilterer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.ui.Keyboard;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import flash.utils.getQualifiedClassName;
   
   public class BetterInventory extends Sprite
   {
      
      private static const MOD_VERSION:String = "1.1.0";
      
      private static const DEBUG_MODE:Boolean = false;
      
      private static const TAB_NEW_INDEX:int = 1;
      
      private static const TAB_MIN_INDEX:int = 1;
      
      private static const TAB_MAX_INDEX:int = 12;
      
      private static const PAGE_SET:String = "NewPipBoyMenu::PageSet";
      
      private static const TAB_SET:String = "NewPipBoyMenu::TabSet";
      
      public var debug_tf:TextField;
      
      private var pipboyMenu:MovieClip;
      
      private var itemInfoMap:Dictionary = new Dictionary();
      
      private var currentTabWeight:String = "0";
      
      private var filterer:ListFilterer;
      
      private var filters:Array = [2,4,8,16,32,64,532480,131072,3072,540672,32768,65536,-1,-1,-1];
      
      private var filterNames:Array = ["New","Weapons","Armor","Apparel","FW","Aid","Misc","Holo","Notes","Junk","Mods","Ammo"];
      
      private var shiftKeyDown:Boolean = false;
      
      private var ctrlKeyDown:Boolean = false;
      
      private var invPage:MovieClip = null;
      
      private var PlayerInventoryData:* = null;
      
      private var isGhoul:Boolean = false;
      
      private var visibilityTimer:Timer = new Timer(33);
      
      private var isINVTabVisible:Boolean = false;
      
      private var lastTabID:int = -1;
      
      private var lastItemFilter:int = -1;
      
      private var knownLocalized:String = "$$Known ";
      
      public function BetterInventory()
      {
         super();
         trace("BetterInventory loaded");
         addEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler);
         this.initDebug();
      }
      
      private function initDebug() : void
      {
         debug_tf = new TextField();
         debug_tf.x = 0;
         debug_tf.y = 0;
         debug_tf.width = 800;
         debug_tf.height = 600;
         debug_tf.text = "";
         debug_tf.wordWrap = true;
         debug_tf.multiline = true;
         var font:TextFormat = new TextFormat("$MAIN_Font",18,16777215);
         debug_tf.defaultTextFormat = font;
         debug_tf.setTextFormat(font);
         debug_tf.selectable = false;
         debug_tf.mouseWheelEnabled = false;
         debug_tf.mouseEnabled = false;
         debug_tf.visible = DEBUG_MODE;
         addChild(debug_tf);
      }
      
      public function displayMessage(param1:*) : void
      {
         debug_tf.text = debug_tf.text + "\n" + param1;
         debug_tf.visible = true;
         debug_tf.scrollV = debug_tf.maxScrollV;
      }
      
      private function addedToStageHandler(param1:Event) : void
      {
         this.log("Added to stage");
         var _loc2_:* = stage.getChildAt(0);
         this.pipboyMenu = "Menu_mc" in _loc2_ ? _loc2_.Menu_mc : null;
         if(Boolean(this.pipboyMenu) && getQualifiedClassName(this.pipboyMenu) == "NewPipBoyMenu")
         {
            if(getQualifiedClassName(this.parent.parent) == "NewPipboy_InvPage")
            {
               this.invPage = this.parent.parent;
               this.visibilityTimer.addEventListener(TimerEvent.TIMER,this.checkForVisibilityChange,false,0,true);
               this.visibilityTimer.start();
            }
            else
            {
               this.log("ERROR: InvPage not found.",getQualifiedClassName(this.parent.parent));
            }
            this.init();
         }
         else
         {
            this.log("FAIL: Not injected into PipboyMenu.",getQualifiedClassName(this.pipboyMenu));
         }
      }
      
      private function init() : void
      {
         var errorCode:String = "init";
         try
         {
            this.log("BetterInventory now initializing");
            errorCode = "bi";
            stage.getChildAt(0)["BetterInventory"] = this;
            errorCode = "PlayerInventoryData";
            this.PlayerInventoryData = BSUIDataManager.GetDataFromClient("PlayerInventoryData");
            errorCode = "keyHandlers";
            stage.addEventListener(KeyboardEvent.KEY_DOWN,this.keyDownHandler);
            stage.addEventListener(KeyboardEvent.KEY_UP,this.keyUpHandler);
            errorCode = "PipBoyINVProvider";
            BSUIDataManager.Subscribe("PipBoyINVProvider",this.onPipBoyINVUpdate);
            errorCode = "localization";
            this.log("BetterInventory initialized");
         }
         catch(e:*)
         {
            this.log("Error initializing BetterInventory: " + errorCode + "\n" + e);
         }
      }
      
      private function checkForVisibilityChange() : void
      {
         if(this.invPage.visible != this.isINVTabVisible)
         {
            this.isINVTabVisible = this.invPage.visible;
            this.log("invPage visible:",this.isINVTabVisible);
            if(this.isINVTabVisible)
            {
               this.preInventoryUpdate();
               this.postInventoryUpdate();
            }
         }
         if(this.isINVTabVisible)
         {
            if(this.lastTabID != this.invPage.CurrentTabIndex)
            {
               this.log("tab change:",this.lastTabID,"->",this.invPage.CurrentTabIndex);
               this.lastTabID = this.invPage.CurrentTabIndex;
               this.preInventoryUpdate();
               this.postInventoryUpdate();
            }
            this.redraw();
         }
      }
      
      private function onPipBoyINVUpdate(param1:Event) : void
      {
         if(this.isINVTabVisible)
         {
            this.log("onPipBoyINVUpdate");
            this.preInventoryUpdate();
            this.postInventoryUpdate();
         }
      }
      
      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      {
         if(this.shiftKeyDown && !param2)
         {
            switch(param1)
            {
               case "Forward":
               case "LTrigger":
                  this.TryToSetTab(TAB_MIN_INDEX);
                  return true;
               case "Back":
               case "RTrigger":
                  this.TryToSetTab(TAB_MAX_INDEX);
                  return true;
               case "StrafeLeft":
               case "Left":
                  this.TryToSetTab(Math.max(TAB_MIN_INDEX,this.invPage.CurrentTabIndex - 2));
                  return true;
               case "StrafeRight":
               case "Right":
                  this.TryToSetTab(Math.min(TAB_MAX_INDEX,this.invPage.CurrentTabIndex + 2));
                  return true;
            }
         }
         return false;
      }
      
      private function keyDownHandler(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.SHIFT)
         {
            this.shiftKeyDown = true;
         }
         else if(param1.keyCode == Keyboard.CONTROL)
         {
            this.ctrlKeyDown = true;
         }
      }
      
      private function keyUpHandler(param1:KeyboardEvent) : void
      {
         var nextTabID:int = -1;
         if(param1.keyCode >= Keyboard.NUMBER_1 && param1.keyCode <= Keyboard.NUMBER_9)
         {
            nextTabID = param1.keyCode - Keyboard.NUMBER_0;
         }
         else if(param1.keyCode == Keyboard.NUMBER_0)
         {
            nextTabID = 10;
         }
         else if(param1.keyCode == Keyboard.MINUS)
         {
            nextTabID = 11;
         }
         else if(param1.keyCode == Keyboard.EQUAL)
         {
            nextTabID = 12;
         }
         if(nextTabID != -1)
         {
            if(!this.shiftKeyDown && !this.ctrlKeyDown)
            {
               this.TryToSetTab(nextTabID);
            }
         }
         if(param1.keyCode == Keyboard.SHIFT)
         {
            this.shiftKeyDown = false;
         }
         else if(param1.keyCode == Keyboard.CONTROL)
         {
            this.ctrlKeyDown = false;
         }
      }
      
      private function preInventoryUpdate() : void
      {
         this.log("preInventoryUpdate");
         this.populateItemInfoMap();
      }
      
      private function postInventoryUpdate() : void
      {
         this.log("postInventoryUpdate");
         this.calcTabWeight();
      }
      
      private function populateItemInfoMap() : void
      {
         this.log("Populate itemInfoMap started",this.invPage.CurrentTabIndex,filters[this.invPage.CurrentTabIndex - 1]);
         var item:Object = null;
         var count:uint = 0;
         var i:int = 0;
         var inv:Array = PlayerInventoryData.data.InventoryList;
         this.log("itemInfoMap source:",inv.length);
         var filter:int = int(this.isINVTabVisible ? filters[this.invPage.CurrentTabIndex - 1] : 0);
         var isNewTab:Boolean = this.invPage.CurrentTabIndex == TAB_NEW_INDEX;
         while(i < inv.length)
         {
            if(Boolean((item = inv[i]).filterFlag & filter) || isNewTab && item.isNew)
            {
               var itemName:String = item.isLearnedRecipe ? this.knownLocalized + item.text : item.text;
               if(this.itemInfoMap[itemName] == null)
               {
                  this.itemInfoMap[itemName] = {
                     "weight":item.weight,
                     "count":item.count
                  };
                  if(false)
                  {
                     CloneObject(item);
                  }
                  count++;
               }
            }
            i++;
         }
         this.log("Populate itemInfoMap finished, entries added:",count);
      }
      
      private function calcTabWeight() : void
      {
         var count:int;
         var records:String;
         var filterer:ListFilterer;
         var tabWeight:Number = NaN;
         var bailoutCounter:int = 0;
         var idx:int = 0;
         var entry:Object = null;
         var infoObj:* = undefined;
         try
         {
            tabWeight = 0;
            bailoutCounter = 5000;
            filterer = this.invPage.List_mc.filterer;
            idx = filterer.GetNextFilterMatch(-1);
            count = 0;
            while(idx != int.MAX_VALUE && Boolean(bailoutCounter--))
            {
               entry = this.invPage.List_mc.entryList[idx];
               infoObj = this.itemInfoMap[entry.Name];
               if(infoObj != null)
               {
                  if(infoObj.weight)
                  {
                     tabWeight += infoObj.weight * infoObj.count;
                  }
                  count++;
               }
               else if(false)
               {
                  log("infoObj NF: " + entry);
                  records = "";
                  for(record in entry)
                  {
                     records += record + ":" + entry[record] + ", ";
                  }
                  log(records,"\n");
               }
               idx = filterer.GetNextFilterMatch(idx);
            }
            if(bailoutCounter <= 0)
            {
               this.log("WARNING: We bailed out of calculating tab weight.");
            }
            this.currentTabWeight = int(tabWeight) == tabWeight ? tabWeight.toFixed(0) : tabWeight.toFixed(1);
            this.log("calcTabWeight (" + count + "): " + this.currentTabWeight);
         }
         catch(e:Error)
         {
            this.log("Calculating tab weight FAILED");
            this.log(e.errorID + " " + e.name + " " + e.message);
         }
      }
      
      private function redraw() : void
      {
         var weightStr:String;
         var bracketIndex:String;
         try
         {
            weightStr = this.pipboyMenu.BottomBar_mc.Info_mc.Weight_tf.text;
            if((bracketIndex = weightStr.indexOf(" [")) != -1)
            {
               weightStr = weightStr.substring(0,bracketIndex);
            }
            weightStr += " [" + this.currentTabWeight + "]";
            this.pipboyMenu.BottomBar_mc.Info_mc.Weight_tf.text = weightStr;
         }
         catch(e:*)
         {
            this.log("redraw error:",e);
         }
      }
      
      private function TryToSetTab(id:uint) : void
      {
         BSUIDataManager.dispatchEvent(new CustomEvent(TAB_SET,{"tabIndex":id}));
      }
      
      public function CloneObject(param1:Object) : *
      {
         var _loc2_:ByteArray = new ByteArray();
         _loc2_.writeObject(param1);
         _loc2_.position = 0;
         return _loc2_.readObject();
      }
      
      private function log(... rest) : void
      {
         if(!DEBUG_MODE)
         {
            return;
         }
         displayMessage(rest.join(" "));
      }
   }
}

