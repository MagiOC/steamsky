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

with Items; use Items;
with ShipModules; use ShipModules;
with Utils; use Utils;
with Ships.Crew; use Ships.Crew;

package body Ships.Cargo is

   procedure UpdateCargo
     (Ship: in out ShipRecord;
      ProtoIndex: Natural := 0;
      Amount: Integer;
      Durability: Natural := 100;
      CargoIndex: Natural := 0) is
      ItemIndex: Natural := 0;
      NewAmount: Integer;
   begin
      if ProtoIndex > 0 then
         for I in Ship.Cargo.Iterate loop
            if Ship.Cargo(I).ProtoIndex = ProtoIndex and
              Ship.Cargo(I).Durability = Durability then
               ItemIndex := Cargo_Container.To_Index(I);
               exit;
            end if;
         end loop;
      else
         ItemIndex := CargoIndex;
      end if;
      if ItemIndex = 0 then
         Ship.Cargo.Append
         (New_Item =>
            (ProtoIndex => ProtoIndex,
             Amount => Amount,
             Name => Null_Unbounded_String,
             Durability => Durability));
      else
         NewAmount := Ship.Cargo(ItemIndex).Amount + Amount;
         if NewAmount < 1 then
            Ship.Cargo.Delete(Index => ItemIndex, Count => 1);
            for Module of Ship.Modules loop
               if Modules_List(Module.ProtoIndex).MType = GUN then
                  if Module.Current_Value > ItemIndex then
                     Module.Current_Value := Module.Current_Value - 1;
                  elsif Module.Current_Value = ItemIndex then
                     Module.Current_Value := 0;
                  end if;
               end if;
            end loop;
         else
            Ship.Cargo(ItemIndex).Amount := NewAmount;
         end if;
      end if;
   end UpdateCargo;

   function FreeCargo(Amount: Integer) return Integer is
      FreeCargo: Integer := 0;
   begin
      for Module of PlayerShip.Modules loop
         if Modules_List(Module.ProtoIndex).MType = ShipModules.CARGO and
           Module.Durability > 0 then
            FreeCargo := FreeCargo + Module.Max_Value;
         end if;
      end loop;
      for Item of PlayerShip.Cargo loop
         FreeCargo :=
           FreeCargo - (Items_List(Item.ProtoIndex).Weight * Item.Amount);
      end loop;
      FreeCargo := FreeCargo + Amount;
      return FreeCargo;
   end FreeCargo;

   function FindCargo
     (ProtoIndex: Natural := 0;
      ItemType: Unbounded_String := Null_Unbounded_String;
      Durability: Natural := 101) return Natural is
      CargoIndex: Natural := 0;
   begin
      if ProtoIndex > 0 then
         for I in PlayerShip.Cargo.Iterate loop
            if Durability < 101 then
               if PlayerShip.Cargo(I).ProtoIndex = ProtoIndex and
                 PlayerShip.Cargo(I).Durability = Durability then
                  CargoIndex := Cargo_Container.To_Index(I);
                  exit;
               end if;
            else
               if PlayerShip.Cargo(I).ProtoIndex = ProtoIndex then
                  CargoIndex := Cargo_Container.To_Index(I);
                  exit;
               end if;
            end if;
         end loop;
      elsif ItemType /= Null_Unbounded_String then
         for I in PlayerShip.Cargo.Iterate loop
            if Durability < 101 then
               if Items_List(PlayerShip.Cargo(I).ProtoIndex).IType =
                 ItemType and
                 PlayerShip.Cargo(I).Durability = Durability then
                  CargoIndex := Cargo_Container.To_Index(I);
                  exit;
               end if;
            else
               if Items_List(PlayerShip.Cargo(I).ProtoIndex).IType =
                 ItemType then
                  CargoIndex := Cargo_Container.To_Index(I);
                  exit;
               end if;
            end if;
         end loop;
      end if;
      return CargoIndex;
   end FindCargo;

   function GetCargoName(CargoIndex: Positive) return String is
   begin
      if PlayerShip.Cargo(CargoIndex).Name /= Null_Unbounded_String then
         return To_String(PlayerShip.Cargo(CargoIndex).Name);
      end if;
      return To_String
          (Items_List(PlayerShip.Cargo(CargoIndex).ProtoIndex).Name);
   end GetCargoName;

   procedure DamageCargo
     (CargoIndex: Positive;
      CrewIndex, SkillIndex: Natural := 0) is
      DamageChance: Integer := 0;
      SelectedItem: constant CargoData := PlayerShip.Cargo(CargoIndex);
      I: Natural := PlayerShip.Cargo.First_Index;
   begin
      if CrewIndex > 0 then
         DamageChance :=
           Items_List(SelectedItem.ProtoIndex).Value -
           (GetSkillLevel(CrewIndex, SkillIndex) / 5);
         if DamageChance < 0 then
            DamageChance := 0;
         end if;
      end if;
      if GetRandom(1, 100) > DamageChance then -- Cargo not damaged
         return;
      end if;
      if SelectedItem.Amount > 1 then
         PlayerShip.Cargo.Append
         (New_Item =>
            (ProtoIndex => SelectedItem.ProtoIndex,
             Amount => (SelectedItem.Amount - 1),
             Name => SelectedItem.Name,
             Durability => SelectedItem.Durability));
         PlayerShip.Cargo(CargoIndex).Amount := 1;
      end if;
      PlayerShip.Cargo(CargoIndex).Durability := SelectedItem.Durability - 1;
      if PlayerShip.Cargo(CargoIndex).Durability = 0 then -- Cargo destroyed
         UpdateCargo
           (PlayerShip,
            PlayerShip.Cargo.Element(CargoIndex).ProtoIndex,
            -1,
            0);
         return;
      end if;
      while I <= PlayerShip.Cargo.Last_Index loop
         for J in
           PlayerShip.Cargo.First_Index .. PlayerShip.Cargo.Last_Index loop
            if PlayerShip.Cargo(I).ProtoIndex =
              PlayerShip.Cargo(J).ProtoIndex and
              PlayerShip.Cargo(I).Durability =
                PlayerShip.Cargo(J).Durability and
              I /= J then
               UpdateCargo
                 (PlayerShip,
                  PlayerShip.Cargo.Element(J).ProtoIndex,
                  (0 - PlayerShip.Cargo.Element(J).Amount),
                  PlayerShip.Cargo.Element(J).Durability);
               UpdateCargo
                 (PlayerShip,
                  PlayerShip.Cargo(I).ProtoIndex,
                  PlayerShip.Cargo(J).Amount,
                  PlayerShip.Cargo(I).Durability);
               I := I - 1;
               exit;
            end if;
         end loop;
         I := I + 1;
      end loop;
   end DamageCargo;

end Ships.Cargo;
