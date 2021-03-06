--    Copyright 2018 Bartek thindil Jasicki
--
--    This file is part of Steam Sky.
--
--    Steam Sky is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    Steam Sky is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with Steam Sky.  If not, see <http://www.gnu.org/licenses/>.

with Gtk.Widget; use Gtk.Widget;
with Gtk.Label; use Gtk.Label;
with Gtk.Tree_Model; use Gtk.Tree_Model;
with Gtk.List_Store; use Gtk.List_Store;
with Gtk.Tree_View; use Gtk.Tree_View;
with Gtk.Tree_View_Column; use Gtk.Tree_View_Column;
with Gtk.Tree_Selection; use Gtk.Tree_Selection;
with Gtk.Adjustment; use Gtk.Adjustment;
with Gtk.Window; use Gtk.Window;
with Gtk.Stack; use Gtk.Stack;
with Glib; use Glib;
with Glib.Object; use Glib.Object;
with Game; use Game;
with Maps; use Maps;
with Messages; use Messages;
with Ships; use Ships;
with Ships.Cargo; use Ships.Cargo;
with Items; use Items;
with Bases.Cargo; use Bases.Cargo;
with Utils.UI; use Utils.UI;

package body Bases.LootUI is

   Builder: Gtkada_Builder;

   procedure ShowItemInfo(Object: access Gtkada_Builder_Record'Class) is
      ItemsIter: Gtk_Tree_Iter;
      ItemsModel: Gtk_Tree_Model;
      ItemInfo: Unbounded_String;
      Amount, ProtoIndex: Natural;
      CargoIndex, BaseCargoIndex: Natural := 0;
      BaseIndex: constant Natural :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      FreeSpace: Integer;
   begin
      Get_Selected
        (Gtk.Tree_View.Get_Selection
           (Gtk_Tree_View(Get_Object(Object, "treeitems"))),
         ItemsModel,
         ItemsIter);
      if ItemsIter = Null_Iter then
         return;
      end if;
      CargoIndex := Natural(Get_Int(ItemsModel, ItemsIter, 1));
      if CargoIndex > Natural(PlayerShip.Cargo.Length) then
         return;
      end if;
      BaseCargoIndex := Natural(Get_Int(ItemsModel, ItemsIter, 2));
      if BaseCargoIndex > Natural(SkyBases(BaseIndex).Cargo.Length) then
         return;
      end if;
      if CargoIndex > 0 then
         ProtoIndex := PlayerShip.Cargo(CargoIndex).ProtoIndex;
      else
         ProtoIndex := SkyBases(BaseIndex).Cargo(BaseCargoIndex).ProtoIndex;
      end if;
      if BaseCargoIndex > 0 then
         Amount := SkyBases(BaseIndex).Cargo(BaseCargoIndex).Amount;
      end if;
      ItemInfo := To_Unbounded_String("Type: ");
      if Items_List(ProtoIndex).ShowType = Null_Unbounded_String then
         Append(ItemInfo, Items_List(ProtoIndex).IType);
      else
         Append(ItemInfo, Items_List(ProtoIndex).ShowType);
      end if;
      Append
        (ItemInfo,
         ASCII.LF &
         "Weight:" &
         Integer'Image(Items_List(ProtoIndex).Weight) &
         " kg");
      if Items_List(ProtoIndex).IType = WeaponType then
         Append
           (ItemInfo,
            ASCII.LF &
            "Skill: " &
            To_String(Skills_List(Items_List(ProtoIndex).Value(3)).Name) &
            "/" &
            To_String
              (Attributes_List
                 (Skills_List(Items_List(ProtoIndex).Value(3)).Attribute)
                 .Name));
         if Items_List(ProtoIndex).Value(4) = 1 then
            Append(ItemInfo, ASCII.LF & "Can be used with shield.");
         else
            Append
              (ItemInfo,
               ASCII.LF & "Can't be used with shield (two-handed weapon).");
         end if;
         Append(ItemInfo, ASCII.LF & "Damage type: ");
         case Items_List(ProtoIndex).Value(5) is
            when 1 =>
               Append(ItemInfo, "cutting");
            when 2 =>
               Append(ItemInfo, "impaling");
            when 3 =>
               Append(ItemInfo, "blunt");
            when others =>
               null;
         end case;
      end if;
      if CargoIndex > 0 then
         Append
           (ItemInfo,
            ASCII.LF &
            "Owned:" &
            Positive'Image(PlayerShip.Cargo(CargoIndex).Amount));
         ShowItemDamage
           (PlayerShip.Cargo(CargoIndex).Durability,
            Get_Object(Object, "lootdamagebar"));
      end if;
      if BaseCargoIndex > 0 then
         if SkyBases(BaseIndex).Cargo(BaseCargoIndex).Amount > 0 then
            Append(ItemInfo, ASCII.LF & "In base:" & Positive'Image(Amount));
         end if;
      end if;
      if Items_List(ProtoIndex).Description /= Null_Unbounded_String then
         Set_Label
           (Gtk_Label(Get_Object(Object, "lbllootdescription")),
            ASCII.LF & To_String(Items_List(ProtoIndex).Description));
      end if;
      Set_Label
        (Gtk_Label(Get_Object(Object, "lbllootinfo")),
         To_String(ItemInfo));
      if CargoIndex = 0 then
         Set_Visible(Gtk_Widget(Get_Object(Object, "dropbox")), False);
      else
         Set_Visible(Gtk_Widget(Get_Object(Object, "dropbox")), True);
         Set_Upper
           (Gtk_Adjustment(Get_Object(Object, "amountadj")),
            Gdouble(PlayerShip.Cargo(CargoIndex).Amount));
      end if;
      if BaseCargoIndex = 0 then
         Set_Visible(Gtk_Widget(Get_Object(Object, "takebox")), False);
      elsif SkyBases(BaseIndex).Cargo(BaseCargoIndex).Amount > 0 then
         Set_Visible(Gtk_Widget(Get_Object(Object, "takebox")), True);
         Set_Upper
           (Gtk_Adjustment(Get_Object(Object, "amountadj1")),
            Gdouble(SkyBases(BaseIndex).Cargo(BaseCargoIndex).Amount));
      end if;
      FreeSpace := FreeCargo(0);
      if FreeSpace < 0 then
         FreeSpace := 0;
      end if;
      Set_Label
        (Gtk_Label(Get_Object(Object, "lblshipspace")),
         "Free cargo space:" & Integer'Image(FreeSpace) & " kg");
   end ShowItemInfo;

   procedure LootItem(User_Data: access GObject_Record'Class) is
      BaseIndex: constant Natural :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      Amount, ProtoIndex: Positive;
      CargoIndex, BaseCargoIndex: Natural := 0;
      ItemsIter: Gtk_Tree_Iter;
      ItemsModel: Gtk_Tree_Model;
   begin
      Get_Selected
        (Gtk.Tree_View.Get_Selection
           (Gtk_Tree_View(Get_Object(Builder, "treeitems"))),
         ItemsModel,
         ItemsIter);
      if ItemsIter = Null_Iter then
         return;
      end if;
      CargoIndex := Natural(Get_Int(ItemsModel, ItemsIter, 1));
      BaseCargoIndex := Natural(Get_Int(ItemsModel, ItemsIter, 2));
      if CargoIndex > 0 then
         ProtoIndex := PlayerShip.Cargo(CargoIndex).ProtoIndex;
      else
         ProtoIndex := SkyBases(BaseIndex).Cargo(BaseCargoIndex).ProtoIndex;
      end if;
      if User_Data = Get_Object(Builder, "btntakeall") then
         Amount := SkyBases(BaseIndex).Cargo(BaseCargoIndex).Amount;
      elsif User_Data = Get_Object(Builder, "btndropall") then
         Amount := PlayerShip.Cargo(CargoIndex).Amount;
      elsif User_Data = Get_Object(Builder, "btndrop") then
         Amount :=
           Positive
             (Get_Value(Gtk_Adjustment(Get_Object(Builder, "amountadj1"))));
      else
         Amount :=
           Positive
             (Get_Value(Gtk_Adjustment(Get_Object(Builder, "amountadj"))));
      end if;
      if User_Data = Get_Object(Builder, "btndropall") or
        User_Data = Get_Object(Builder, "btndrop") then
         if BaseCargoIndex > 0 then
            UpdateBaseCargo
              (CargoIndex => BaseCargoIndex,
               Amount => Amount,
               Durability => PlayerShip.Cargo.Element(CargoIndex).Durability);
         else
            UpdateBaseCargo
              (ProtoIndex,
               Amount,
               PlayerShip.Cargo.Element(CargoIndex).Durability);
         end if;
         UpdateCargo
           (Ship => PlayerShip,
            CargoIndex => CargoIndex,
            Amount => (0 - Amount),
            Durability => PlayerShip.Cargo.Element(CargoIndex).Durability);
         AddMessage
           ("You drop" &
            Positive'Image(Amount) &
            " " &
            To_String(Items_List(ProtoIndex).Name) &
            ".",
            OrderMessage);
      else
         if FreeCargo(0 - (Amount * Items_List(ProtoIndex).Weight)) < 0 then
            ShowDialog
              ("You can't take that much " &
               To_String(Items_List(ProtoIndex).Name) &
               ".",
               Gtk_Window(Get_Object(Builder, "skymapwindow")));
            return;
         end if;
         if CargoIndex > 0 then
            UpdateCargo
              (Ship => PlayerShip,
               CargoIndex => CargoIndex,
               Amount => Amount,
               Durability =>
                 SkyBases(BaseIndex).Cargo(BaseCargoIndex).Durability);
         else
            UpdateCargo
              (PlayerShip,
               ProtoIndex,
               Amount,
               SkyBases(BaseIndex).Cargo(BaseCargoIndex).Durability);
         end if;
         UpdateBaseCargo
           (CargoIndex => BaseCargoIndex,
            Amount => (0 - Amount),
            Durability =>
              SkyBases(BaseIndex).Cargo.Element(BaseCargoIndex).Durability);
         AddMessage
           ("You took" &
            Positive'Image(Amount) &
            " " &
            To_String(Items_List(ProtoIndex).Name) &
            ".",
            OrderMessage);
      end if;
      UpdateGame(10);
      ShowLootUI;
   end LootItem;

   procedure CreateBasesLootUI(NewBuilder: Gtkada_Builder) is
   begin
      Builder := NewBuilder;
      Register_Handler(Builder, "Show_Item_Info", ShowItemInfo'Access);
      Register_Handler(Builder, "Loot_Item", LootItem'Access);
   end CreateBasesLootUI;

   procedure ShowLootUI is
      ItemsIter: Gtk_Tree_Iter;
      ItemsList: Gtk_List_Store;
      BaseIndex: constant Natural :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      BaseType: constant Positive :=
        Bases_Types'Pos(SkyBases(BaseIndex).BaseType) + 1;
      IndexesList: Positive_Container.Vector;
      BaseCargoIndex: Natural;
   begin
      ItemsList := Gtk_List_Store(Get_Object(Builder, "itemslist2"));
      Clear(ItemsList);
      for I in PlayerShip.Cargo.Iterate loop
         if Items_List(PlayerShip.Cargo(I).ProtoIndex).Prices(BaseType) >
           0 then
            Append(ItemsList, ItemsIter);
            Set(ItemsList, ItemsIter, 0, GetItemName(PlayerShip.Cargo(I)));
            Set
              (ItemsList,
               ItemsIter,
               1,
               Gint(Inventory_Container.To_Index(I)));
            BaseCargoIndex :=
              FindBaseCargo
                (PlayerShip.Cargo(I).ProtoIndex,
                 PlayerShip.Cargo(I).Durability);
            if BaseCargoIndex > 0 then
               IndexesList.Append(New_Item => BaseCargoIndex);
            end if;
            Set(ItemsList, ItemsIter, 2, Gint(BaseCargoIndex));
         end if;
      end loop;
      for I in
        SkyBases(BaseIndex).Cargo.First_Index ..
            SkyBases(BaseIndex).Cargo.Last_Index loop
         if IndexesList.Find_Index(Item => I) = 0 then
            Append(ItemsList, ItemsIter);
            Set
              (ItemsList,
               ItemsIter,
               0,
               To_String
                 (Items_List(SkyBases(BaseIndex).Cargo(I).ProtoIndex).Name));
            Set(ItemsList, ItemsIter, 1, 0);
            Set(ItemsList, ItemsIter, 2, Gint(I));
         end if;
      end loop;
      Set_Visible_Child_Name
        (Gtk_Stack(Get_Object(Builder, "gamestack")),
         "loot");
      Set_Deletable(Gtk_Window(Get_Object(Builder, "skymapwindow")), False);
      Hide(Gtk_Widget(Get_Object(Builder, "dropbox")));
      Hide(Gtk_Widget(Get_Object(Builder, "takebox")));
      Set_Cursor
        (Gtk_Tree_View(Get_Object(Builder, "treeitems")),
         Gtk_Tree_Path_New_From_String("0"),
         Gtk_Tree_View_Column(Get_Object(Builder, "columnname1")),
         False);
      ShowLastMessage(Builder);
   end ShowLootUI;

end Bases.LootUI;
