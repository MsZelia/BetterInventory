package
{
   import Shared.AS3.Data.*;
   import Shared.AS3.Events.*;
   import com.adobe.serialization.json.*;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.KeyboardEvent;
   import flash.events.TimerEvent;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import flash.utils.getQualifiedClassName;
   import flash.utils.setTimeout;
   
   public class BetterInventory extends Sprite
   {
      
      private static const MOD_VERSION:String = "2.0.4";
      
      private static const TAB_NEW_INDEX:int = 1;
      
      private static const TAB_MIN_INDEX:int = 1;
      
      private static const TAB_MAX_INDEX:int = 12;
      
      private static const PAGE_SET:String = "NewPipBoyMenu::PageSet";
      
      private static const TAB_SET:String = "NewPipBoyMenu::TabSet";
      
      private static var DEBUG_MODE:Boolean = false;
      
      public var debug_tf:TextField;
      
      private var pipboyMenu:MovieClip;
      
      private var currentTabWeight:String = "0";
      
      private var filters:Array = [2,4,8,16,32,64,12288,131072,3072,278528,32768,65536,-1,-1,-1];
      
      private var filterNames:Array = ["New","Weapons","Armor","Apparel","FW","Aid","Misc","Holo","Notes","Junk","Mods","Ammo"];
      
      private var shiftKeyDown:Boolean = false;
      
      private var ctrlKeyDown:Boolean = false;
      
      private var invPage:MovieClip = null;
      
      private var PlayerInventoryData:* = null;
      
      private var visibilityTimer:Timer = new Timer(20);
      
      private var isINVTabVisible:Boolean = false;
      
      private var lastTabID:int = -1;
      
      private var lastItemFilter:int = -1;
      
      public var config:Object = null;
      
      public function BetterInventory()
      {
         super();
         trace("BetterInventory loaded");
         addEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler);
         this.debug_tf.visible = DEBUG_MODE;
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
            errorCode = "loadConfig";
            setTimeout(this.loadConfig,25);
            this.log("BetterInventory initialized",MOD_VERSION);
         }
         catch(e:*)
         {
            this.log("Error initializing BetterInventory: " + errorCode + "\n" + e);
         }
      }
      
      private function loadConfig() : void
      {
         var loaderComplete:*;
         var ioErrorHandler:*;
         var url:URLRequest = null;
         var loader:URLLoader = null;
         try
         {
            loaderComplete = function(param1:Event):void
            {
               try
               {
                  config = new JSONDecoder(loader.data,true).getValue();
                  DEBUG_MODE = config.debug;
                  invPage.List_mc.enableScrollWrap = !config.disableScrollWrap;
                  log("Config file loaded!");
               }
               catch(e:Error)
               {
                  log("Error parsing config file!",e);
               }
            };
            ioErrorHandler = function(param1:*):void
            {
               log("Error loading config!",param1.text);
            };
            url = new URLRequest("../BetterInventoryConfig.json");
            loader = new URLLoader();
            loader.load(url);
            loader.addEventListener(Event.COMPLETE,loaderComplete,false,0,true);
            loader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler,false,0,true);
         }
         catch(e:Error)
         {
            this.log("Error loading config:",e);
         }
      }
      
      private function checkForVisibilityChange() : void
      {
         if(this.invPage.visible != this.isINVTabVisible)
         {
            this.isINVTabVisible = this.invPage.visible;
            if(this.isINVTabVisible)
            {
               this.calcTabWeight();
            }
         }
         if(this.isINVTabVisible)
         {
            if(this.lastTabID != this.invPage.CurrentTabIndex)
            {
               this.log("tab change:",this.lastTabID,"->",this.invPage.CurrentTabIndex);
               this.lastTabID = this.invPage.CurrentTabIndex;
               this.calcTabWeight();
            }
            this.redraw();
         }
      }
      
      private function onPipBoyINVUpdate(param1:Event) : void
      {
         if(this.isINVTabVisible)
         {
            this.log("onPipBoyINVUpdate");
            this.calcTabWeight();
         }
      }
      
      private function onPipBoySelectionChange(param1:*) : void
      {
         if(!param1.data.ItemDetails || !param1.data.ItemDetails.InfoCardData)
         {
            return;
         }
         var wt:Number = 0;
         var infoCardData:Array = param1.data.ItemDetails.InfoCardData;
         var info:* = undefined;
         for each(info in infoCardData)
         {
            if(info.text == "$wt")
            {
               wt = Number(info.value);
               break;
            }
         }
         this.log("selected wt:",wt);
      }
      
      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      {
         if(config != null && config.disableShiftHotkeys)
         {
            return false;
         }
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
         if(config == null || !config.disableNumericalHotkeys)
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
      
      private function calcTabWeight() : void
      {
         var item:Object;
         var count:uint;
         var i:int;
         var inv:Array;
         var filter:int;
         var tabWeight:Number;
         try
         {
            this.log("calcTabWeight started",this.invPage.CurrentTabIndex,filters[this.invPage.CurrentTabIndex - 1]);
            item = null;
            count = 0;
            i = 0;
            inv = PlayerInventoryData.data.InventoryList;
            filter = int(this.isINVTabVisible ? filters[this.invPage.CurrentTabIndex - 1] : 0);
            tabWeight = 0;
            while(i < inv.length)
            {
               if(Boolean((item = inv[i]).filterFlag & filter))
               {
                  tabWeight += item.weight * item.count;
                  count++;
               }
               i++;
            }
            this.currentTabWeight = int(tabWeight) == tabWeight ? tabWeight.toFixed(0) : tabWeight.toFixed(1);
            this.log("currentTabWeight (" + count + "):",this.currentTabWeight);
         }
         catch(e:*)
         {
            this.log("calcTabWeight error:",e);
         }
      }
      
      private function redraw() : void
      {
         var weightStr:String;
         var bracketIndex:String;
         try
         {
            if(!this.isINVTabVisible)
            {
               return;
            }
            if(config != null && config.disableCategoryWeight)
            {
               return;
            }
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

