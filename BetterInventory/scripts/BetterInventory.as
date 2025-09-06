package
{
   import Shared.AS3.BSButtonHintData;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Events.PlatformChangeEvent;
   import Shared.AS3.ListFilterer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   
   public class BetterInventory extends Sprite
   {
      
      private static const DEBUG_MODE:Boolean = false;
      
      private static const SAVE_FILTER_MODES:Boolean = false;
      
      private static const STATS_PAGE_INDEX:int = 0;
      
      private static const INV_PAGE_INDEX:int = 1;
      
      private static const TAB_NEW_INDEX:int = 0;
      
      private static const TAB_WEAPONS_INDEX:int = 1;
      
      private static const TAB_ARMOR_INDEX:int = 2;
      
      private static const TAB_APPAREL_INDEX:int = 3;
      
      private static const TAB_FOOD_DRINK_INDEX:int = 4;
      
      private static const TAB_AID_INDEX:int = 5;
      
      private static const TAB_MISC_INDEX:int = 6;
      
      private static const TAB_NOTES_INDEX:int = 8;
      
      private static const TAB_AMMO_INDEX:int = 11;
      
      private static const TAB_MIN_INDEX:int = TAB_NEW_INDEX;
      
      private static const TAB_MAX_INDEX:int = TAB_AMMO_INDEX;
      
      public var debug_tf:TextField;
      
      private var pipboyMenu:MovieClip;
      
      private var filterButton:BSButtonHintData;
      
      private var _bIsDirty:Boolean;
      
      private var _buttonHintsInitialized:Boolean = false;
      
      private var itemInfoMap:Dictionary = new Dictionary();
      
      private var paperDollMap:Dictionary = new Dictionary();
      
      private var currentTab:int = -1;
      
      private var currentTabWeight:String = "0";
      
      private var filterer:ListFiltererEx;
      
      private var savedFilterMode:Array = [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1];
      
      private var shiftKeyDown:Boolean = false;
      
      private var ctrlKeyDown:Boolean = false;
      
      private var disableFilterChangeOnCtrl:Boolean = false;
      
      private var _translator:TextField = new TextField();
      
      private var _weightStr:String = "";
      
      private var selectedTabLabelOverride:String = "";
      
      private var _stackWeightInvalidated:Boolean = false;
      
      private var invPage:MovieClip = null;
      
      private var HUDRightMetersData:* = null;
      
      private var isGhoul:Boolean = false;
      
      public function BetterInventory()
      {
         super();
         trace("BetterInventory loaded");
         this.debug_tf.visible = false;
         this.filterButton = new BSButtonHintData("$FILTER","Ctrl","PSN_L1","Xenon_L1",1,this.onFilterButtonPress);
         addEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler);
         this.HUDRightMetersData = BSUIDataManager.GetDataFromClient("HUDRightMetersData").data;
      }
      
      private function init() : void
      {
         var oldItemFilter:int;
         this.log("BetterInventory now initializing");
         stage.getChildAt(0)["BetterInventory"] = this;
         stage.addEventListener(PipboyChangeEvent.PIPBOY_CHANGE_EVENT,this.prePipboyChangeEvent,false,int.MAX_VALUE);
         stage.addEventListener(PipboyChangeEvent.PIPBOY_CHANGE_EVENT,this.postPipboyChangeEvent,false,1);
         stage.addEventListener(KeyboardEvent.KEY_DOWN,this.keyDownHandler);
         stage.addEventListener(KeyboardEvent.KEY_UP,this.keyUpHandler);
         this.invPage.List_mc.addEventListener(MouseEvent.MOUSE_WHEEL,this.invListMouseWheelHandler);
         this.invPage.addEventListener("PipboyPage::LowerPipboyAllowedChange",this.onLowerPipboyAllowedChange,false,int.MIN_VALUE);
         try
         {
            this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.Selected.textField_tf.addEventListener(MouseEvent.CLICK,this.onTabClicked);
            this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.Selected.textField_tf.addEventListener(MouseEvent.MOUSE_WHEEL,this.onTabMouseWheel);
         }
         catch(e:Error)
         {
            log("WARN: init(): Some QOL features could not be activated. Check missing paths?");
            log(e.errorID + " " + e.name + " " + e.message);
         }
         this.invPage.addEventListener("PipboyPage::BottomBarUpdate",this.onBottomBarUpdate,false,int.MIN_VALUE);
         oldItemFilter = int(this.invPage.List_mc.filterer.itemFilter);
         this.filterer = new ListFiltererEx(this.itemInfoMap,this.paperDollMap);
         this.filterer.itemFilter = oldItemFilter;
         this.invPage.List_mc.filterer = this.filterer;
         this.invPage.List_mc.InvalidateData();
         this._translator.text = "$wt";
         this._weightStr = this._translator.text;
         if(this.pipboyMenu.DataObj.CurrentPage == INV_PAGE_INDEX)
         {
            this.preInventoryUpdate(this.pipboyMenu.DataObj);
            this.postInventoryUpdate(this.pipboyMenu.DataObj);
            this.SetIsDirty();
         }
         this.isGhoul = this.HUDRightMetersData.feralPercent != -1;
      }
      
      private function onLowerPipboyAllowedChange(param1:Event) : void
      {
         this.log("PipboyPage::LowerPipboyAllowedChange - CanLowerPipboy:",this.invPage.CanLowerPipboy());
         this.updateFilterButton();
      }
      
      private function onBottomBarUpdate(param1:Event) : void
      {
         this.log("onBottomBarUpdate");
         this._stackWeightInvalidated = true;
         this.SetIsDirty();
      }
      
      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      {
         if(this.shiftKeyDown && !param2)
         {
            switch(param1)
            {
               case "Forward":
               case "LTrigger":
                  this.pipboyMenu.TryToSetTab(TAB_MIN_INDEX);
                  return true;
               case "Back":
               case "RTrigger":
                  this.pipboyMenu.TryToSetTab(TAB_MAX_INDEX);
                  return true;
               case "StrafeLeft":
               case "Left":
                  this.pipboyMenu.TryToSetTab(Math.max(TAB_MIN_INDEX,this.pipboyMenu.DataObj.CurrentTab - 2));
                  return true;
               case "StrafeRight":
               case "Right":
                  this.pipboyMenu.TryToSetTab(Math.min(TAB_MAX_INDEX,this.pipboyMenu.DataObj.CurrentTab + 2));
                  return true;
            }
         }
         if(this.pipboyMenu.uiPlatform == PlatformChangeEvent.PLATFORM_PC_KB_MOUSE)
         {
            return false;
         }
         var _loc3_:Boolean = false;
         if(!param2)
         {
            if(param1 == "LShoulder")
            {
               this.onFilterButtonPress();
               _loc3_ = true;
            }
         }
         return _loc3_;
      }
      
      private function addedToStageHandler(param1:Event) : void
      {
         this.log("Added to stage");
         var _loc2_:* = stage.getChildAt(0);
         this.pipboyMenu = "Menu_mc" in _loc2_ ? _loc2_.Menu_mc : null;
         this.log("movieRoot:",_loc2_);
         this.log("pipboyMenu:",this.pipboyMenu);
         if(Boolean(this.pipboyMenu) && getQualifiedClassName(this.pipboyMenu) == "PipboyMenu")
         {
            if(getQualifiedClassName(this.pipboyMenu.CurrentPage) == "Pipboy_InvPage")
            {
               this.invPage = this.pipboyMenu.CurrentPage;
            }
            this.init();
         }
         else
         {
            this.log("FAIL: Not injected into PipboyMenu.");
         }
      }
      
      final private function onRenderEvent(param1:Event) : void
      {
         if(stage)
         {
            stage.removeEventListener(Event.RENDER,this.onRenderEvent);
         }
         if(this._bIsDirty)
         {
            this._bIsDirty = false;
            this.redraw();
         }
      }
      
      private function invListMouseWheelHandler(param1:MouseEvent) : void
      {
         if(this.ctrlKeyDown)
         {
            this.disableFilterChangeOnCtrl = true;
         }
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
         switch(param1.keyCode)
         {
            case Keyboard.CONTROL:
               if(!this.disableFilterChangeOnCtrl)
               {
                  this.onFilterButtonPress();
               }
               else
               {
                  this.disableFilterChangeOnCtrl = false;
               }
               break;
            case Keyboard.ALTERNATE:
               this.onFilterPreviousPress();
         }
         if(param1.keyCode == Keyboard.BACKQUOTE)
         {
            if(this.pipboyMenu.DataObj.CurrentPage == INV_PAGE_INDEX)
            {
               if(!this.isGhoul)
               {
                  if(this.pipboyMenu.DataObj.CurrentTab != TAB_FOOD_DRINK_INDEX)
                  {
                     this.savedFilterMode[TAB_FOOD_DRINK_INDEX] = ListFiltererEx.FILTER_FW_FOOD_COOKED;
                     this.pipboyMenu.TryToSetTab(TAB_FOOD_DRINK_INDEX);
                  }
                  else if(this.filterer.extraFilterType != ListFiltererEx.FILTER_FW_FOOD_COOKED)
                  {
                     this.applyFilter(ListFiltererEx.FILTER_FW_FOOD_COOKED);
                  }
               }
            }
            else if(this.pipboyMenu.DataObj.CurrentPage == STATS_PAGE_INDEX)
            {
               this.pipboyMenu.TryToSetPage(INV_PAGE_INDEX);
            }
         }
         var _loc2_:int = -1;
         if(param1.keyCode >= Keyboard.NUMBER_1 && param1.keyCode <= Keyboard.NUMBER_9)
         {
            _loc2_ = param1.keyCode - Keyboard.NUMBER_1;
         }
         else if(param1.keyCode == Keyboard.NUMBER_0)
         {
            _loc2_ = 9;
         }
         else if(param1.keyCode == Keyboard.MINUS)
         {
            _loc2_ = 10;
         }
         else if(param1.keyCode == Keyboard.EQUAL)
         {
            _loc2_ = 11;
         }
         if(_loc2_ != -1)
         {
            if(this.shiftKeyDown || this.ctrlKeyDown)
            {
               if(this.ctrlKeyDown)
               {
                  this.disableFilterChangeOnCtrl = true;
               }
               this.onSetFilterMode(_loc2_);
            }
            else
            {
               this.pipboyMenu.TryToSetTab(_loc2_);
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
      
      private function prePipboyChangeEvent(param1:PipboyChangeEvent) : void
      {
         if(param1.UpdateMask.Intersects(PipboyUpdateMask.Inventory))
         {
            if(param1.DataObj.CurrentPage == INV_PAGE_INDEX)
            {
               this.preInventoryUpdate(param1.DataObj);
            }
         }
      }
      
      private function postPipboyChangeEvent(param1:PipboyChangeEvent) : void
      {
         if(param1.UpdateMask.Intersects(PipboyUpdateMask.Inventory))
         {
            if(param1.DataObj.CurrentPage == INV_PAGE_INDEX)
            {
               this.postInventoryUpdate(param1.DataObj);
            }
            this.updateFilterButton();
         }
         this.SetIsDirty();
      }
      
      private function preInventoryUpdate(param1:Pipboy_DataObj) : void
      {
         this.populateItemInfoMap(param1.InvItems,param1.InvFilter);
      }
      
      private function postInventoryUpdate(param1:Pipboy_DataObj) : void
      {
         if(this.currentTab != param1.CurrentTab)
         {
            this.log("Tab changed from",this.currentTab,"to",param1.CurrentTab);
            if(this.currentTab > -1)
            {
            }
            this.applyFilter(this.savedFilterMode[param1.CurrentTab]);
            this.log("Restored saved filter mode:",this.savedFilterMode[param1.CurrentTab]);
            this.currentTab = param1.CurrentTab;
         }
         this.calcTabWeight();
      }
      
      private function applyFilter(param1:int) : void
      {
         if(SAVE_FILTER_MODES)
         {
            this.savedFilterMode[this.pipboyMenu.DataObj.CurrentTab] = param1;
         }
         this.filterer.extraFilterType = param1;
         this.updateFilterButton();
         this.calcTabWeight();
         this.SetIsDirty();
         this.invPage.List_mc.InvalidateData();
      }
      
      private function updateFilterButton() : void
      {
         this.filterButton.ButtonVisible = this.pipboyMenu.DataObj.CurrentPage == INV_PAGE_INDEX && (this.pipboyMenu.DataObj.CurrentTab == TAB_WEAPONS_INDEX || this.pipboyMenu.DataObj.CurrentTab == TAB_ARMOR_INDEX || this.pipboyMenu.DataObj.CurrentTab == TAB_APPAREL_INDEX || this.pipboyMenu.DataObj.CurrentTab == TAB_FOOD_DRINK_INDEX || this.pipboyMenu.DataObj.CurrentTab == TAB_AID_INDEX || this.pipboyMenu.DataObj.CurrentTab == TAB_NOTES_INDEX) && Boolean(this.invPage.CanLowerPipboy());
         if(!this.filterButton.ButtonVisible)
         {
            return;
         }
         var _loc1_:String = ListFiltererEx.GetFilterText(this.filterer.extraFilterType);
         if(_loc1_ == "")
         {
            this.filterButton.ButtonText = "$FILTER";
            this.selectedTabLabelOverride = this.invPage.TabNames[this.pipboyMenu.DataObj.CurrentTab];
         }
         else
         {
            this.filterButton.ButtonText = "$$FILTER" + " (" + _loc1_ + ")";
            this.selectedTabLabelOverride = "$" + this.invPage.TabNames[this.pipboyMenu.DataObj.CurrentTab] + " (" + _loc1_ + ")";
         }
         this.SetIsDirty();
      }
      
      private function setSelectedTabLabel(param1:String) : void
      {
         var _loc2_:Number = 12.5;
         this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.Selected.textField_tf.text = param1;
         this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.LeftOne.x = this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.Selected.x - this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.Selected.width / 2 - this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.LeftOne.width / 2 - _loc2_;
         this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.LeftTwo.x = this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.LeftOne.x - this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.LeftOne.width / 2 - this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.LeftTwo.width / 2 - _loc2_;
         this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.RightOne.x = this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.Selected.x + this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.Selected.width / 2 + this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.RightOne.width / 2 + _loc2_;
         this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.RightTwo.x = this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.RightOne.x + this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.RightOne.width / 2 + this.pipboyMenu.Header_mc.TabHeader_mc.AlphaHolder.RightTwo.width / 2 + _loc2_;
      }
      
      private function populateItemInfoMap(param1:Array, param2:int) : void
      {
         var _loc5_:Object = null;
         var _loc6_:Array = null;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc3_:uint = 0;
         this.log("Populate itemInfoMap started");
         var _loc4_:int = 0;
         while(_loc4_ < param1.length)
         {
            if(Boolean((_loc5_ = param1[_loc4_]).filterFlag & param2) || this.pipboyMenu.DataObj.CurrentTab == TAB_NEW_INDEX && _loc5_.isNew)
            {
               if(this.itemInfoMap[_loc5_.serverHandleID] == null)
               {
                  _loc6_ = [];
                  _loc7_ = new Array();
                  _loc8_ = int(_loc5_.nodeID);
                  this.invPage.codeObj.onInvItemSelection(_loc8_,_loc6_,_loc7_,this.invPage,_loc5_.serverHandleID);
                  this.itemInfoMap[_loc5_.serverHandleID] = _loc6_;
                  this.paperDollMap[_loc5_.serverHandleID] = _loc7_;
                  _loc3_++;
               }
            }
            _loc4_++;
         }
         this.log("Populate itemInfoMap finished, entries added:",_loc3_);
      }
      
      private function onTabClicked(param1:MouseEvent) : void
      {
         if(this.shiftKeyDown)
         {
            this.onFilterPreviousPress();
         }
         else
         {
            this.onFilterButtonPress();
         }
      }
      
      private function onTabMouseWheel(param1:MouseEvent) : void
      {
         if(param1.delta < 0)
         {
            this.onFilterButtonPress();
         }
         else
         {
            this.onFilterPreviousPress();
         }
      }
      
      private function onFilterButtonPress() : void
      {
         if(!this.filterButton.ButtonVisible || !this.filterButton.ButtonEnabled)
         {
            return;
         }
         this.log("onFilterButtonPress");
         this.advanceFilterMode(1);
      }
      
      private function onFilterPreviousPress() : void
      {
         if(!this.filterButton.ButtonVisible || !this.filterButton.ButtonEnabled)
         {
            return;
         }
         this.log("onFilterPreviousPress");
         this.advanceFilterMode(-1);
      }
      
      private function advanceFilterMode(param1:int = 1) : void
      {
         this.log("Advancing filter mode by",param1);
         var _loc2_:int = this.filterer.extraFilterType;
         _loc2_ += param1;
         var _loc3_:Array = ListFiltererEx.GetFilterIndexBoundaries(this.pipboyMenu.DataObj.CurrentTab);
         if(_loc2_ < -1)
         {
            _loc2_ = int(_loc3_[1]);
         }
         else if(_loc2_ < _loc3_[0])
         {
            _loc2_ = param1 > 0 ? int(_loc3_[0]) : -1;
         }
         else if(_loc2_ > _loc3_[1])
         {
            _loc2_ = -1;
         }
         if(isGhoul && _loc2_ >= ListFiltererEx.FILTER_FW_FOOD && _loc2_ <= ListFiltererEx.FILTER_FW_WATER_COOKED)
         {
            _loc2_ = param1 > 0 ? int(ListFiltererEx.FILTER_FW_WATER_COOKED + 1) : -1;
         }
         this.applyFilter(_loc2_);
      }
      
      private function onSetFilterMode(param1:int) : void
      {
         if(!this.filterButton.ButtonVisible || !this.filterButton.ButtonEnabled)
         {
            return;
         }
         this.log("onSetFilterMode",param1);
         if(param1 == 0)
         {
            this.applyFilter(-1);
            return;
         }
         var _loc2_:Array = ListFiltererEx.GetFilterIndexBoundaries(this.pipboyMenu.DataObj.CurrentTab);
         var _loc3_:* = _loc2_[0] + (param1 - 1);
         if(_loc3_ < _loc2_[0] || _loc3_ > _loc2_[1])
         {
            return;
         }
         this.applyFilter(_loc3_);
      }
      
      private function calcTabWeight() : void
      {
         var tabWeight:Number = NaN;
         var bailoutCounter:int = 0;
         var filterer:ListFilterer = null;
         var idx:int = 0;
         var entry:Object = null;
         var infoArr:Array = null;
         var infoObj:* = undefined;
         var weight:Number = NaN;
         try
         {
            tabWeight = 0;
            bailoutCounter = 5000;
            filterer = this.invPage.List_mc.filterer;
            idx = filterer.GetNextFilterMatch(-1);
            while(idx != int.MAX_VALUE && Boolean(bailoutCounter--))
            {
               entry = this.invPage.List_mc.entryList[idx];
               infoArr = this.itemInfoMap[entry.serverHandleID];
               if(infoArr == null)
               {
                  this.log("WARN: calcTabWeight() - no info object for",entry.text,"serverHandleID",entry.serverHandleID);
               }
               for each(infoObj in infoArr)
               {
                  if(infoObj.text == "$wt")
                  {
                     weight = Number(infoObj.value);
                     tabWeight += weight * entry.count;
                     break;
                  }
               }
               idx = filterer.GetNextFilterMatch(idx);
            }
            if(bailoutCounter <= 0)
            {
               this.log("WARNING: We bailed out of calculating tab weight.");
            }
            this.currentTabWeight = int(tabWeight) == tabWeight ? tabWeight.toFixed(0) : tabWeight.toFixed(1);
         }
         catch(e:Error)
         {
            log("Calculating tab weight FAILED");
            log(e.errorID + " " + e.name + " " + e.message);
         }
      }
      
      private function initButtonHints() : void
      {
         var _loc1_:int = 0;
         this.invPage.buttonHintDataV.splice(0,0,this.filterButton);
         if(this.pipboyMenu.uiPlatform != PlatformChangeEvent.PLATFORM_PC_KB_MOUSE)
         {
            _loc1_ = this.invPage.buttonHintDataV.length - 1;
            while(_loc1_ >= 0)
            {
               if(this.invPage.buttonHintDataV[_loc1_].XenonButton == "Xenon_L1")
               {
                  this.invPage.buttonHintDataV.splice(_loc1_,1);
                  break;
               }
               _loc1_--;
            }
         }
         this.pipboyMenu.ButtonHintBar_mc.SetButtonHintData(this.invPage.buttonHintDataV);
      }
      
      private function redraw() : void
      {
         var weightStr:String;
         var selectedEntry:Object = null;
         var weightSingle:Number = NaN;
         var infoObj:* = undefined;
         var i:int = 0;
         var itemCard:MovieClip = null;
         var actualLabelWidth:Number = NaN;
         var labelWidthDiff:Number = NaN;
         var weightSingleDecimalPlaces:int = 0;
         var totalWeight:Number = NaN;
         if(!this._buttonHintsInitialized)
         {
            this._buttonHintsInitialized = true;
            this.initButtonHints();
         }
         weightStr = Math.floor(this.pipboyMenu.DataObj.CurrWeight) + "/" + Math.floor(this.pipboyMenu.DataObj.MaxWeight) + " [" + this.currentTabWeight + "]";
         this.pipboyMenu.BottomBar_mc.Info_mc.Weight_tf.text = weightStr;
         if(this.selectedTabLabelOverride != "")
         {
            this.setSelectedTabLabel(this.selectedTabLabelOverride);
            this.selectedTabLabelOverride = "";
         }
         if(this._stackWeightInvalidated)
         {
            this._stackWeightInvalidated = false;
            try
            {
               selectedEntry = this.invPage.List_mc.selectedEntry;
               if(Boolean(selectedEntry) && selectedEntry.count > 1)
               {
                  weightSingle = -1;
                  for each(infoObj in this.invPage.ItemCard_mc.InfoObj)
                  {
                     if(infoObj.text == "$wt")
                     {
                        weightSingle = Number(infoObj.value);
                        break;
                     }
                  }
                  if(weightSingle == -1)
                  {
                     throw new Error("Unable to find weight info object");
                  }
                  i = 0;
                  while(i < this.invPage.ItemCard_mc.numChildren)
                  {
                     itemCard = this.invPage.ItemCard_mc.getChildAt(i) as MovieClip;
                     if(getQualifiedClassName(itemCard) == "ItemCard_StandardEntry")
                     {
                        if(itemCard.Label_tf.text == this._weightStr)
                        {
                           actualLabelWidth = itemCard.Label_tf.getLineMetrics(0).width + 5;
                           labelWidthDiff = itemCard.Label_tf.width - actualLabelWidth;
                           if(labelWidthDiff > 0)
                           {
                              itemCard.Label_tf.width = actualLabelWidth;
                              itemCard.Value_tf.x -= labelWidthDiff;
                              itemCard.Value_tf.width += labelWidthDiff;
                           }
                           weightSingleDecimalPlaces = itemCard.Value_tf.text.indexOf(".") > -1 ? int(itemCard.Value_tf.text.length - 1 - itemCard.Value_tf.text.indexOf(".")) : 0;
                           totalWeight = weightSingle * selectedEntry.count;
                           itemCard.Value_tf.text = itemCard.Value_tf.text + " [" + totalWeight.toFixed(weightSingleDecimalPlaces) + "]";
                           break;
                        }
                     }
                     i++;
                  }
               }
            }
            catch(e:Error)
            {
               log("Calculating stack weight FAILED");
               log(e.errorID + " " + e.name + " " + e.message);
            }
         }
      }
      
      private function SetIsDirty() : void
      {
         this._bIsDirty = true;
         if(stage)
         {
            stage.addEventListener(Event.RENDER,this.onRenderEvent,false,int.MIN_VALUE);
            stage.invalidate();
         }
      }
      
      private function RoundDecimal(param1:Number, param2:uint) : String
      {
         var _loc5_:int = 0;
         var _loc3_:String = param1.toFixed(param2);
         var _loc4_:int = int(_loc3_.indexOf("."));
         if(_loc4_ > -1)
         {
            _loc5_ = _loc3_.length - 1;
            while(_loc5_ >= _loc4_)
            {
               if(_loc3_.charAt(_loc5_) != "0")
               {
                  return _loc3_.substring(0,_loc5_ == _loc4_ ? _loc5_ : _loc5_ + 1);
               }
               _loc5_--;
            }
         }
         return _loc3_;
      }
      
      private function log(... rest) : void
      {
         if(!DEBUG_MODE)
         {
            return;
         }
         if(invPage != null && invPage.log != null)
         {
            invPage.log(rest.join(" "));
         }
      }
   }
}

