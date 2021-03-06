--    Copyright 2017-2018 Bartek thindil Jasicki
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

with Maps; use Maps;
with Items; use Items;
with Ships; use Ships;
with Utils; use Utils;
with Trades; use Trades;

package body Bases.Cargo is

   procedure GenerateCargo is
      BaseIndex: constant Positive :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      BaseType: constant Positive :=
        Bases_Types'Pos(SkyBases(BaseIndex).BaseType) + 1;
      Chance, Roll: Positive;
      Population: Natural := SkyBases(BaseIndex).Population;
      MaxAmount: Natural;
   begin
      if Population = 0 then
         Population := 1;
      end if;
      if SkyBases(BaseIndex).Population < 150 then
         Chance := 5;
      elsif SkyBases(BaseIndex).Population > 149 and
        SkyBases(BaseIndex).Population < 300 then
         Chance := 10;
      else
         Chance := 15;
      end if;
      Chance := Chance + DaysDifference(SkyBases(BaseIndex).Visited);
      if SkyBases(BaseIndex).Cargo.Length = 0 then
         Chance := 101;
      end if;
      if GetRandom(1, 100) > Chance then
         return;
      end if;
      if SkyBases(BaseIndex).Cargo.Length = 0 then
         SkyBases(BaseIndex).Cargo.Append
         (New_Item =>
            (ProtoIndex => FindProtoItem(MoneyIndex),
             Amount => (GetRandom(50, 200) * Population),
             Durability => 100,
             Price => 0));
         for I in Items_List.Iterate loop
            if Items_List(I).Buyable(BaseType) then
               SkyBases(BaseIndex).Cargo.Append
               (New_Item =>
                  (ProtoIndex => Objects_Container.To_Index(I),
                   Amount => (GetRandom(0, 100) * Population),
                   Durability => 100,
                   Price => Items_List(I).Prices(BaseType)));
            end if;
         end loop;
      else
         for Item of SkyBases(BaseIndex).Cargo loop
            Roll := GetRandom(1, 100);
            if Roll < 30 and Item.Amount > 0 then
               MaxAmount := Item.Amount / 2;
               if MaxAmount < 1 then
                  MaxAmount := 1;
               end if;
               Item.Amount := Item.Amount - GetRandom(1, MaxAmount);
            elsif Roll < 60 and SkyBases(BaseIndex).Population > 0 then
               if Item.Amount = 0 then
                  Item.Amount := GetRandom(1, 10) * Population;
               else
                  MaxAmount := Item.Amount / 2;
                  if MaxAmount < 1 then
                     MaxAmount := 1;
                  end if;
                  Item.Amount := Item.Amount + GetRandom(1, MaxAmount);
               end if;
            end if;
         end loop;
      end if;
   end GenerateCargo;

   procedure UpdateBaseCargo
     (ProtoIndex: Natural := 0;
      Amount: Integer;
      Durability: Natural := 100;
      CargoIndex: Natural := 0) is
      BaseIndex: constant Positive :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      BaseType: constant Positive :=
        Bases_Types'Pos(SkyBases(BaseIndex).BaseType) + 1;
      ItemIndex: Natural;
   begin
      if ProtoIndex > 0 then
         ItemIndex := FindBaseCargo(ProtoIndex, Durability);
      else
         ItemIndex := CargoIndex;
      end if;
      if Amount > 0 then
         if ItemIndex = 0 then
            SkyBases(BaseIndex).Cargo.Append
            (New_Item =>
               (ProtoIndex => ProtoIndex,
                Amount => Amount,
                Durability => Durability,
                Price => Items_List(ProtoIndex).Prices(BaseType)));
         else
            SkyBases(BaseIndex).Cargo(ItemIndex).Amount :=
              SkyBases(BaseIndex).Cargo(ItemIndex).Amount + Amount;
         end if;
      else
         SkyBases(BaseIndex).Cargo(ItemIndex).Amount :=
           SkyBases(BaseIndex).Cargo(ItemIndex).Amount + Amount;
         if SkyBases(BaseIndex).Cargo(ItemIndex).Amount = 0 and
           not Items_List(SkyBases(BaseIndex).Cargo(ItemIndex).ProtoIndex)
             .Buyable
             (BaseType) and
           ItemIndex > 1 then
            SkyBases(BaseIndex).Cargo.Delete(Index => ItemIndex);
         end if;
      end if;
   end UpdateBaseCargo;

   function FindBaseCargo
     (ProtoIndex: Positive;
      Durability: Natural := 101) return Natural is
      BaseIndex: constant Natural :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
   begin
      if BaseIndex > 0 then
         for I in SkyBases(BaseIndex).Cargo.Iterate loop
            if Durability < 101 then
               if SkyBases(BaseIndex).Cargo(I).ProtoIndex = ProtoIndex and
                 SkyBases(BaseIndex).Cargo(I).Durability = Durability then
                  return BaseCargo_Container.To_Index(I);
               end if;
            else
               if SkyBases(BaseIndex).Cargo(I).ProtoIndex = ProtoIndex then
                  return BaseCargo_Container.To_Index(I);
               end if;
            end if;
         end loop;
      else
         for I in TraderCargo.Iterate loop
            if Durability < 101 then
               if TraderCargo(I).ProtoIndex = ProtoIndex and
                 TraderCargo(I).Durability = Durability then
                  return BaseCargo_Container.To_Index(I);
               end if;
            else
               if TraderCargo(I).ProtoIndex = ProtoIndex then
                  return BaseCargo_Container.To_Index(I);
               end if;
            end if;
         end loop;
      end if;
      return 0;
   end FindBaseCargo;

end Bases.Cargo;
