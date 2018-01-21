--    Copyright 2017 Bartek thindil Jasicki
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

with Utils.UI; use Utils.UI;

package body Items.UI is

   procedure ShowItemStatus
     (Inventory: Inventory_Container.Vector;
      ItemIndex: Positive;
      InfoWindow: Window;
      Line: Line_Position) is
      DamagePercent: constant Natural :=
        100 -
        Natural((Float(Inventory(ItemIndex).Durability) / 100.0) * 100.0);
      TextLength: Integer;
      TextColor: Color_Pair;
   begin
      TextLength := Integer(GetStatusLength(Inventory, ItemIndex)) - 12;
      if TextLength < 1 then
         return;
      end if;
      case DamagePercent is
         when 1 .. 19 =>
            Add(Win => InfoWindow, Str => "Slightly used");
            TextColor := 2;
         when 20 .. 49 =>
            Add(Win => InfoWindow, Str => "Damaged");
            TextColor := 1;
         when 50 .. 79 =>
            Add(Win => InfoWindow, Str => "Heavily damaged");
            TextColor := 3;
         when others =>
            Add(Win => InfoWindow, Str => "Almost destroyed");
            TextColor := 4;
      end case;
      Change_Attributes
        (Win => InfoWindow,
         Line => Line,
         Column => 8,
         Count => TextLength,
         Color => TextColor);
   end ShowItemStatus;

   function ShowItemInfo
     (Inventory: Inventory_Container.Vector;
      ItemIndex: Positive) return Line_Position is
      InfoWindow, BoxWindow: Window;
      ProtoIndex: constant Positive := Inventory(ItemIndex).ProtoIndex;
      ItemWeight: constant Positive :=
        Inventory(ItemIndex).Amount * Items_List(ProtoIndex).Weight;
      WindowHeight: Line_Position := 8;
      WindowWidth: Column_Position;
      CurrentLine: Line_Position := 1;
   begin
      if Inventory(ItemIndex).Durability < 100 then
         WindowHeight := WindowHeight + 1;
      end if;
      if Items_List(ProtoIndex).IType = WeaponType then
         WindowHeight := WindowHeight + 1;
      end if;
      WindowHeight :=
        WindowHeight +
        Line_Position
          ((Length(Items_List(ProtoIndex).Description) /
            (Natural(Columns / 2) - 4)));
      WindowWidth :=
        Column_Position(Length(Items_List(ProtoIndex).Description) + 5);
      if WindowWidth <
        Column_Position
          (Positive'Image(Items_List(ProtoIndex).Weight)'Length + 5) then
         WindowWidth :=
           Column_Position
             (Positive'Image(Items_List(ProtoIndex).Weight)'Length + 5);
      end if;
      if WindowWidth < GetStatusLength(Inventory, ItemIndex) then
         WindowWidth := GetStatusLength(Inventory, ItemIndex);
      end if;
      if WindowWidth > (Columns / 2) then
         WindowWidth := Columns / 2;
      end if;
      BoxWindow := Create(WindowHeight, WindowWidth, 3, (Columns / 2));
      WindowFrame(BoxWindow, 2, "Item info");
      InfoWindow :=
        Create(WindowHeight - 2, WindowWidth - 4, 4, (Columns / 2) + 2);
      Add(Win => InfoWindow, Str => "Type: ");
      if Items_List(ProtoIndex).ShowType = Null_Unbounded_String then
         Add
           (Win => InfoWindow,
            Str => To_String(Items_List(ProtoIndex).IType));
      else
         Add
           (Win => InfoWindow,
            Str => To_String(Items_List(ProtoIndex).ShowType));
      end if;
      Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 0);
      Add
        (Win => InfoWindow,
         Str => "Amount:" & Positive'Image(Inventory(ItemIndex).Amount));
      CurrentLine := CurrentLine + 1;
      Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 0);
      Add
        (Win => InfoWindow,
         Str =>
           "Weight:" & Positive'Image(Items_List(ProtoIndex).Weight) & " kg");
      CurrentLine := CurrentLine + 1;
      Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 0);
      Add
        (Win => InfoWindow,
         Str => "Total weight:" & Positive'Image(ItemWeight) & " kg");
      CurrentLine := CurrentLine + 1;
      if Items_List(ProtoIndex).IType = WeaponType then
         Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 0);
         Add
           (Win => InfoWindow,
            Str =>
              "Skill: " &
              To_String(Skills_List(Items_List(ProtoIndex).Value(3)).Name) &
              "/" &
              To_String
                (Attributes_Names
                   (Skills_List(Items_List(ProtoIndex).Value(3)).Attribute)));
         CurrentLine := CurrentLine + 1;
      end if;
      if Inventory(ItemIndex).Durability < 100 then
         Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 0);
         Add(Win => InfoWindow, Str => "Status: ");
         ShowItemStatus(Inventory, ItemIndex, InfoWindow, CurrentLine);
         CurrentLine := CurrentLine + 1;
      end if;
      if Items_List(ProtoIndex).Description /= Null_Unbounded_String then
         CurrentLine := CurrentLine + 1;
         Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 0);
         Add
           (Win => InfoWindow,
            Str => To_String(Items_List(ProtoIndex).Description));
      end if;
      Refresh_Without_Update;
      Refresh_Without_Update(BoxWindow);
      Delete(BoxWindow);
      Refresh_Without_Update(InfoWindow);
      Delete(InfoWindow);
      return WindowHeight + 3;
   end ShowItemInfo;

   function GetStatusLength
     (Inventory: Inventory_Container.Vector;
      ItemIndex: Positive) return Column_Position is
      DamagePercent: constant Natural :=
        100 -
        Natural((Float(Inventory(ItemIndex).Durability) / 100.0) * 100.0);
   begin
      case DamagePercent is
         when 0 =>
            return 0;
         when 1 .. 19 =>
            return 25;
         when 20 .. 49 =>
            return 19;
         when 50 .. 79 =>
            return 27;
         when others =>
            return 28;
      end case;
   end GetStatusLength;

end Items.UI;