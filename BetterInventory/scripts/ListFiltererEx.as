package
{
   import Shared.AS3.ListFilterer;
   import flash.text.TextField;
   import flash.utils.Dictionary;
   
   public class ListFiltererEx extends ListFilterer
   {
      
      private static var FILTER_COUNT:uint = 0;
      
      public static const FILTER_WEAP_START:uint = 0;
      
      public static const FILTER_WEAP_RANGED:uint = 0;
      
      public static const FILTER_WEAP_MELEE:uint = 1;
      
      public static const FILTER_WEAP_THROWN:uint = 2;
      
      public static const FILTER_WEAP_END:uint = 2;
      
      public static const FILTER_ARMOR_START:uint = 3;
      
      public static const FILTER_ARMOR_CHEST:uint = 3;
      
      public static const FILTER_ARMOR_ARM_L:uint = 4;
      
      public static const FILTER_ARMOR_ARM_R:uint = 5;
      
      public static const FILTER_ARMOR_LEG_L:uint = 6;
      
      public static const FILTER_ARMOR_LEG_R:uint = 7;
      
      public static const FILTER_ARMOR_POWER_ARMOR:uint = 8;
      
      public static const FILTER_ARMOR_OTHER:uint = 9;
      
      public static const FILTER_ARMOR_END:uint = 9;
      
      public static const FILTER_APPAREL_START:uint = 10;
      
      public static const FILTER_APPAREL_OUTFIT:uint = 10;
      
      public static const FILTER_APPAREL_UNDERARMOR:uint = 11;
      
      public static const FILTER_APPAREL_HAT:uint = 12;
      
      public static const FILTER_APPAREL_EYEWEAR:uint = 13;
      
      public static const FILTER_APPAREL_MASK:uint = 14;
      
      public static const FILTER_APPAREL_HEADGEAR:uint = 15;
      
      public static const FILTER_APPAREL_BACKPACK:uint = 16;
      
      public static const FILTER_APPAREL_END:uint = 16;
      
      public static const FILTER_FW_START:uint = 17;
      
      public static const FILTER_FW_FOOD:uint = 17;
      
      public static const FILTER_FW_WATER:uint = 18;
      
      public static const FILTER_FW_FOOD_COOKED:uint = 19;
      
      public static const FILTER_FW_WATER_COOKED:uint = 20;
      
      public static const FILTER_FW_FISH:uint = 21;
      
      public static const FILTER_FW_OTHER:uint = 22;
      
      public static const FILTER_FW_END:uint = 22;
      
      public static const FILTER_AID_START:uint = 23;
      
      public static const FILTER_AID_CHEM:uint = 23;
      
      public static const FILTER_AID_BOBBLEHEAD:uint = 24;
      
      public static const FILTER_AID_MAGAZINE:uint = 25;
      
      public static const FILTER_AID_SERUM:uint = 26;
      
      public static const FILTER_AID_ATX:uint = 27;
      
      public static const FILTER_AID_OTHER:uint = 28;
      
      public static const FILTER_AID_END:uint = 28;
      
      public static const FILTER_MISC_START:uint = 29;
      
      public static const FILTER_MISC_NON_KEYS:uint = 29;
      
      public static const FILTER_MISC_KEYS:uint = 30;
      
      public static const FILTER_MISC_END:uint = 30;
      
      public static const FILTER_NOTES_START:uint = 31;
      
      public static const FILTER_NOTES_UNREAD:uint = 31;
      
      public static const FILTER_NOTES_END:uint = 31;
      
      private static var FISH_LOCALIZED:String = "";
      
      private static var ATOM_GLYPH:String = "";
      
      private static const FISH_LOCALIZATION_LOOKUP_KEY:String = "$FishingNoBait";
      
      private static const FISH_LOCALIZATION_LOOKUP:* = {
         "You do not have enough of this bait.":"Fish",
         "Vous n\'avez pas assez de cet appât.":"poisson",
         "No tienes suficiente carnaza de este tipo.":"Pez",
         "No tienes suficiente carnada de este tipo.":"Pez",
         "Du hast nicht genug von diesem Köder vorrätig.":"Fisch",
         "Non hai abbastanza esche di questo tipo.":"Pesce",
         "Masz za mało tej przynęty.":"ryba",
         "Você tem pouco dessa isca.":"Peixe",
         "Недостаточно наживки этого типа.":"рыба",
         "この餌が足りません":"型の魚",
         "이 미끼의 숫자가 부족합니다.":"물고기입니다.",
         "此鱼饵数量不足。":"型鱼类",
         "該種魚餌數量不足。":"型魚類"
      };
      
      public var infoMap:Dictionary;
      
      public var paperDollMap:Dictionary;
      
      public var extraFilterType:int = -1;
      
      public var ITEM_FILTER_MISC:uint = 1 << 12;
      
      public function ListFiltererEx(param1:Dictionary, param2:Dictionary)
      {
         super();
         this.infoMap = param1;
         this.paperDollMap = param2;
         var loc_tf:TextField = new TextField();
         loc_tf.text = FISH_LOCALIZATION_LOOKUP_KEY;
         FISH_LOCALIZED = (FISH_LOCALIZATION_LOOKUP[loc_tf.text] || "").toLowerCase();
         loc_tf.text = "$ATOMSGLYPH";
         ATOM_GLYPH = loc_tf.text;
      }
      
      public static function GetFilterIndexBoundaries(param1:int) : Array
      {
         switch(param1)
         {
            case 1:
               return [FILTER_WEAP_START,FILTER_WEAP_END];
            case 2:
               return [FILTER_ARMOR_START,FILTER_ARMOR_END];
            case 3:
               return [FILTER_APPAREL_START,FILTER_APPAREL_END];
            case 4:
               return [FILTER_FW_START,FILTER_FW_END];
            case 5:
               return [FILTER_AID_START,FILTER_AID_END];
            case 8:
               return [FILTER_NOTES_START,FILTER_NOTES_END];
            default:
               return [-1,-1];
         }
      }
      
      public static function GetFilterText(param1:int) : String
      {
         switch(param1)
         {
            case FILTER_WEAP_RANGED:
               return "RANGED";
            case FILTER_WEAP_MELEE:
               return "MELEE";
            case FILTER_WEAP_THROWN:
               return "THROWN";
            case FILTER_ARMOR_CHEST:
               return "CHEST";
            case FILTER_ARMOR_ARM_L:
               return "ARM - L";
            case FILTER_ARMOR_ARM_R:
               return "ARM - R";
            case FILTER_ARMOR_LEG_L:
               return "LEG - L";
            case FILTER_ARMOR_LEG_R:
               return "LEG - R";
            case FILTER_ARMOR_POWER_ARMOR:
               return "POWER";
            case FILTER_ARMOR_OTHER:
               return "OTHER";
            case FILTER_APPAREL_OUTFIT:
               return "OUTFIT";
            case FILTER_APPAREL_UNDERARMOR:
               return "UNDERARMOR";
            case FILTER_APPAREL_HAT:
               return "HAT";
            case FILTER_APPAREL_EYEWEAR:
               return "EYEWEAR";
            case FILTER_APPAREL_MASK:
               return "MASK";
            case FILTER_APPAREL_HEADGEAR:
               return "HEADGEAR";
            case FILTER_APPAREL_BACKPACK:
               return "BACKPACK";
            case FILTER_FW_FOOD:
               return "FOOD";
            case FILTER_FW_WATER:
               return "WATER";
            case FILTER_FW_FOOD_COOKED:
               return "FOOD*";
            case FILTER_FW_WATER_COOKED:
               return "WATER*";
            case FILTER_FW_FISH:
               return FISH_LOCALIZED.toUpperCase() || "FISH";
            case FILTER_FW_OTHER:
               return "OTHER";
            case FILTER_AID_CHEM:
               return "CHEM";
            case FILTER_AID_BOBBLEHEAD:
               return "BOBBLEHEAD";
            case FILTER_AID_MAGAZINE:
               return "MAGAZINE";
            case FILTER_AID_SERUM:
               return "SERUM";
            case FILTER_AID_ATX:
               return "ATX";
            case FILTER_AID_OTHER:
               return "OTHER";
            case FILTER_MISC_NON_KEYS:
               return "*";
            case FILTER_MISC_KEYS:
               return "KEYS";
            case FILTER_NOTES_UNREAD:
               return "UNREAD";
            default:
               return "";
         }
      }
      
      override public function EntryMatchesFilter(param1:Object) : Boolean
      {
         var _loc2_:Array = null;
         var _loc3_:Array = null;
         if(this.extraFilterType == -1)
         {
            return param1 != null && (!param1.hasOwnProperty("filterFlag") || (param1.filterFlag & this.itemFilter) != 0);
         }
         if(param1 == null || Boolean(param1.hasOwnProperty("filterFlag")) && (param1.filterFlag & this.itemFilter) == 0)
         {
            return false;
         }
         _loc2_ = this.infoMap[param1.serverHandleID];
         if(_loc2_ == null)
         {
            return false;
         }
         switch(this.extraFilterType)
         {
            case FILTER_WEAP_RANGED:
               if(this.isRanged(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_WEAP_MELEE:
               if(this.isMelee(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_WEAP_THROWN:
               if(this.isThrown(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_ARMOR_CHEST:
            case FILTER_ARMOR_ARM_L:
            case FILTER_ARMOR_ARM_R:
            case FILTER_ARMOR_LEG_L:
            case FILTER_ARMOR_LEG_R:
               _loc3_ = this.paperDollMap[param1.serverHandleID];
               if(_loc3_ == null)
               {
                  return false;
               }
               if(!this.isOutfit(_loc2_) && this.occupiesApparelSlot(_loc3_,this.extraFilterType,true))
               {
                  return true;
               }
               break;
            case FILTER_ARMOR_POWER_ARMOR:
               _loc3_ = this.paperDollMap[param1.serverHandleID];
               if(_loc3_ == null)
               {
                  return false;
               }
               if(param1.itemLevel == 0 && _loc3_.length == 0)
               {
                  return true;
               }
               break;
            case FILTER_ARMOR_OTHER:
               _loc3_ = this.paperDollMap[param1.serverHandleID];
               if(_loc3_ == null)
               {
                  return false;
               }
               if(param1.itemLevel != 0 && _loc3_.indexOf(true) == -1)
               {
                  return true;
               }
               break;
            case FILTER_APPAREL_UNDERARMOR:
            case FILTER_APPAREL_HAT:
            case FILTER_APPAREL_EYEWEAR:
            case FILTER_APPAREL_MASK:
               _loc3_ = this.paperDollMap[param1.serverHandleID];
               if(_loc3_ == null)
               {
                  return false;
               }
               if(this.isOutfit(_loc2_) && this.occupiesOnlyApparelSlot(_loc3_,this.extraFilterType))
               {
                  return true;
               }
               break;
            case FILTER_APPAREL_OUTFIT:
               _loc3_ = this.paperDollMap[param1.serverHandleID];
               if(_loc3_ == null)
               {
                  return false;
               }
               if(this.isLevelZero(_loc2_) && _loc3_.indexOf(true) == -1)
               {
                  return true;
               }
               break;
            case FILTER_APPAREL_HEADGEAR:
               _loc3_ = this.paperDollMap[param1.serverHandleID];
               if(_loc3_ == null || _loc3_.length == 0)
               {
                  return false;
               }
               if(this.isOutfit(_loc2_) && this.isHeadgear(_loc3_))
               {
                  return true;
               }
               break;
            case FILTER_APPAREL_BACKPACK:
               _loc3_ = this.paperDollMap[param1.serverHandleID];
               if(_loc3_ == null)
               {
                  return false;
               }
               if(!this.isLevelZero(_loc2_) && _loc3_.indexOf(true) == -1)
               {
                  return true;
               }
               break;
            case FILTER_FW_FOOD:
               if(this.isFood(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_FW_WATER:
               if(this.isWater(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_FW_FOOD_COOKED:
               if(this.isCookedFood(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_FW_WATER_COOKED:
               if(this.isCookedWater(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_FW_FISH:
               if(this.isFish(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_FW_OTHER:
               if(this.isOtherFoodWater(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_AID_CHEM:
               if(this.isChem(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_AID_BOBBLEHEAD:
               if(this.isBobblehead(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_AID_MAGAZINE:
               if(this.isMagazine(_loc2_) && !this.isAtx(param1))
               {
                  return true;
               }
               break;
            case FILTER_AID_SERUM:
               if(this.isSerum(_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_AID_ATX:
               if(this.isAtx(param1))
               {
                  return true;
               }
               break;
            case FILTER_AID_OTHER:
               if(!this.isChem(_loc2_) && !this.isSerum(_loc2_) && !this.isBobblehead(_loc2_) && !this.isMagazine(_loc2_) && !this.isAtx(param1))
               {
                  return true;
               }
               break;
            case FILTER_MISC_NON_KEYS:
               if(!this.isEntryKey(param1,_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_MISC_KEYS:
               if(this.isEntryKey(param1,_loc2_))
               {
                  return true;
               }
               break;
            case FILTER_NOTES_UNREAD:
               if(!this.hasBeenRead(param1))
               {
                  return true;
               }
               break;
         }
         return false;
      }
      
      private function isFood(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$Food" && parseInt(_loc2_.value) > 0)
            {
               return true;
            }
         }
         return false;
      }
      
      private function isWater(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$Water" && parseInt(_loc2_.value) > 0)
            {
               return true;
            }
         }
         return false;
      }
      
      private function isCookedFood(param1:Array) : Boolean
      {
         var _loc3_:* = undefined;
         var _loc2_:int = 2;
         for each(_loc3_ in param1)
         {
            if(_loc3_.text == "$Food" && String(_loc3_.value).charAt(0) != "-")
            {
               _loc2_--;
            }
            if(_loc3_.text == "currentHealth" && int(_loc3_.value) == -1)
            {
               return false;
            }
            if(_loc3_.text == "maximumHealth" && int(_loc3_.value) > 0)
            {
               _loc2_--;
            }
            if(_loc3_.text == "Disease Chance")
            {
               return false;
            }
         }
         return _loc2_ == 0;
      }
      
      private function isCookedWater(param1:Array) : Boolean
      {
         var _loc3_:* = undefined;
         var _loc2_:int = 2;
         for each(_loc3_ in param1)
         {
            if(_loc3_.text == "$Water" && String(_loc3_.value).charAt(0) != "-")
            {
               _loc2_--;
            }
            if(_loc3_.text == "currentHealth" && int(_loc3_.value) == -1)
            {
               return false;
            }
            if(_loc3_.text == "maximumHealth" && int(_loc3_.value) > 0)
            {
               _loc2_--;
            }
            if(_loc3_.text == "Disease Chance")
            {
               return false;
            }
         }
         return _loc2_ == 0;
      }
      
      private function isFish(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(Boolean(_loc2_.showAsDescription) && _loc2_.text.toLowerCase().indexOf(FISH_LOCALIZED) != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      private function isOtherFoodWater(param1:Array) : Boolean
      {
         return !(this.isWater(param1) || this.isCookedWater(param1)) && !(this.isFood(param1) || this.isCookedFood(param1)) && !this.isFish(param1);
      }
      
      private function isChem(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$Food")
            {
               return true;
            }
            if(_loc2_.text == "$Water")
            {
               return true;
            }
         }
         return false;
      }
      
      private function isSerum(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         var _loc3_:int = 2;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$wt" && Number(_loc2_.value) == 0.25)
            {
               _loc3_--;
            }
            if(_loc2_.text == "$val" && int(_loc2_.value) == 2000)
            {
               _loc3_--;
            }
         }
         return _loc3_ == 0;
      }
      
      private function isBobblehead(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         var _loc3_:int = 2;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$wt" && this.CloseToNumber(_loc2_.value,0.01,0.0001))
            {
               _loc3_--;
            }
            if(_loc2_.text == "$val" && int(_loc2_.value) == 100)
            {
               _loc3_--;
            }
         }
         return _loc3_ == 0;
      }
      
      private function isMagazine(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         var _loc3_:int = 1;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$wt" && this.CloseToNumber(_loc2_.value,0.01,0.0001))
            {
               _loc3_--;
            }
            if(_loc2_.text == "$val")
            {
               return false;
            }
         }
         return _loc3_ == 0;
      }
      
      private function isAtx(param1:Object) : Boolean
      {
         return param1.text.indexOf(ATOM_GLYPH) != -1;
      }
      
      private function isRanged(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$ROF" && Number(_loc2_.value) > 0)
            {
               return true;
            }
         }
         return false;
      }
      
      private function isMelee(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$speed")
            {
               return true;
            }
         }
         return false;
      }
      
      private function isThrown(param1:Array) : Boolean
      {
         return !isMelee(param1) && !isRanged(param1);
      }
      
      private function isOutfit(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "currentHealth" && int(_loc2_.value) == -1)
            {
               return true;
            }
         }
         return false;
      }
      
      private function isHeadgear(param1:Array) : Boolean
      {
         var slotsOccupied:int = 0;
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_)
            {
               slotsOccupied++;
            }
         }
         if(slotsOccupied > 1)
         {
            return param1[6] || param1[7] || param1[8];
         }
         return false;
      }
      
      private function isLevelZero(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "itemLevel" && int(_loc2_.value) == 0)
            {
               return true;
            }
         }
         return false;
      }
      
      private function occupiesApparelSlot(param1:Array, param2:uint, param3:Boolean = false) : Boolean
      {
         if(param3)
         {
            if(param1[0])
            {
               return false;
            }
         }
         switch(param2)
         {
            case FILTER_APPAREL_UNDERARMOR:
               return param1[0];
            case FILTER_ARMOR_LEG_L:
               return param1[1];
            case FILTER_ARMOR_LEG_R:
               return param1[2];
            case FILTER_ARMOR_ARM_L:
               return param1[3];
            case FILTER_ARMOR_ARM_R:
               return param1[4];
            case FILTER_ARMOR_CHEST:
               return param1[5];
            case FILTER_APPAREL_HAT:
               return param1[6];
            case FILTER_APPAREL_EYEWEAR:
               return param1[7];
            case FILTER_APPAREL_MASK:
               return param1[8];
            default:
               return false;
         }
      }
      
      private function occupiesOnlyApparelSlot(param1:Array, param2:uint) : Boolean
      {
         var slotsOccupied:int = 0;
         var _loc3_:* = undefined;
         for each(_loc3_ in param1)
         {
            if(_loc3_)
            {
               slotsOccupied++;
            }
         }
         if(slotsOccupied == 1)
         {
            switch(param2)
            {
               case FILTER_APPAREL_UNDERARMOR:
                  return param1[0];
               case FILTER_ARMOR_LEG_L:
                  return param1[1];
               case FILTER_ARMOR_LEG_R:
                  return param1[2];
               case FILTER_ARMOR_ARM_L:
                  return param1[3];
               case FILTER_ARMOR_ARM_R:
                  return param1[4];
               case FILTER_ARMOR_CHEST:
                  return param1[5];
               case FILTER_APPAREL_HAT:
                  return param1[6];
               case FILTER_APPAREL_EYEWEAR:
                  return param1[7];
               case FILTER_APPAREL_MASK:
                  return param1[8];
               default:
                  return false;
            }
         }
         return false;
      }
      
      private function isKey(param1:Array) : Boolean
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in param1)
         {
            if(_loc2_.text == "$wt")
            {
               return Number(_loc2_.value) == 0;
            }
         }
         return false;
      }
      
      private function isEntryKey(param1:Object, param2:Array) : Boolean
      {
         return param1.filterFlag == this.ITEM_FILTER_MISC && this.isKey(param2);
      }
      
      private function hasBeenRead(param1:Object) : Boolean
      {
         return param1.isLearned;
      }
      
      private function CloseToNumber(param1:Number, param2:Number, param3:Number = 0.001) : Boolean
      {
         return Math.abs(param1 - param2) < param3;
      }
   }
}

