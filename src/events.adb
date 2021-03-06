--    Copyright 2016-2018 Bartek thindil Jasicki
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

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ships; use Ships;
with Ships.Cargo; use Ships.Cargo;
with Ships.Crew; use Ships.Crew;
with Ships.Movement; use Ships.Movement;
with Maps; use Maps;
with Combat; use Combat;
with Messages; use Messages;
with Crew; use Crew;
with Bases; use Bases;
with ShipModules; use ShipModules;
with Items; use Items;
with Utils; use Utils;
with Game; use Game;
with Factions; use Factions;

package body Events is

   Traders, FriendlyShips: Positive_Container.Vector;

   function CheckForEvent return Boolean is
      TimePassed: Integer;
      CrewIndex, PlayerValue: Natural := 0;
      Roll,
      Roll2,
      ItemIndex,
      EnemyIndex,
      EngineIndex,
      Injuries,
      LostCargo: Positive;
      Enemies, Engines: Positive_Container.Vector;
      BaseIndex: constant Natural :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      procedure GenerateEnemies
        (Owner: Unbounded_String := To_Unbounded_String("Any")) is
      begin
         EnemyIndex := ProtoShips_List.First_Index;
         if GetRandom(1, 100) < 99 then
            PlayerValue := CountCombatValue;
            for Ship of ProtoShips_List loop
               if Ship.CombatValue <= PlayerValue and
                 (Owner = To_Unbounded_String("Any") or
                  To_Lower(To_String(Factions_List(Ship.Owner).Index)) =
                    To_Lower(To_String(Owner))) and
                 not Factions_List(Ship.Owner).Friendly then
                  Enemies.Append(New_Item => EnemyIndex);
               end if;
               EnemyIndex := EnemyIndex + 1;
            end loop;
         else
            for Ship of ProtoShips_List loop
               if
                 (Owner = To_Unbounded_String("Any") or
                  To_Lower(To_String(Factions_List(Ship.Owner).Index)) =
                    To_Lower(To_String(Owner))) and
                 not Factions_List(Ship.Owner).Friendly then
                  Enemies.Append(New_Item => EnemyIndex);
               end if;
               EnemyIndex := EnemyIndex + 1;
            end loop;
         end if;
      end GenerateEnemies;
      procedure GainPerception is
      begin
         for I in PlayerShip.Crew.Iterate loop
            if PlayerShip.Crew(I).Order = Pilot or
              PlayerShip.Crew(I).Order = Gunner then
               GainExp(1, PerceptionSkill, Crew_Container.To_Index(I));
            end if;
         end loop;
      end GainPerception;
   begin
      if SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex > 0 then
         case Events_List(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex)
           .EType is
            when EnemyShip =>
               return StartCombat
                   (Events_List
                      (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex)
                      .Data);
            when others =>
               return False;
         end case;
      end if;
      if GetRandom(1, 100) < 7 then -- Event happen
         Roll := GetRandom(1, 100);
         if BaseIndex = 0 then -- Outside bases
            case Roll is
               when 1 .. 5 => -- Engine damaged
                  CrewIndex := FindMember(Engineer);
                  if CrewIndex > 0 and PlayerShip.Speed /= FULL_STOP then
                     Roll2 := GetRandom(1, 100);
                     case PlayerShip.Speed is
                        when QUARTER_SPEED =>
                           if Roll2 < 21 then
                              Roll2 := 1;
                           else
                              Roll2 := Roll2 - 20;
                           end if;
                        when FULL_SPEED =>
                           Roll2 := Roll2 + 20;
                        when others =>
                           null;
                     end case;
                     if Roll2 >
                       GetSkillLevel
                         (PlayerShip.Crew(CrewIndex),
                          EngineeringSkill) then
                        AddMessage
                          ("One of your engines is taking damage.",
                           OtherMessage,
                           3);
                        for I in
                          PlayerShip.Modules.First_Index ..
                              PlayerShip.Modules.Last_Index loop
                           if Modules_List(PlayerShip.Modules(I).ProtoIndex)
                               .MType =
                             ENGINE then
                              Engines.Append(New_Item => I);
                           end if;
                        end loop;
                        EngineIndex :=
                          Engines
                            (GetRandom
                               (Engines.First_Index,
                                Engines.Last_Index));
                        PlayerShip.Modules(EngineIndex).Durability :=
                          PlayerShip.Modules(EngineIndex).Durability - 1;
                        UpdateOrders(PlayerShip);
                     else
                        AddMessage
                          (To_String(PlayerShip.Crew(CrewIndex).Name) &
                           " has prevented engine damage.",
                           OtherMessage,
                           2);
                     end if;
                     GainExp(1, EngineeringSkill, CrewIndex);
                  end if;
               when 6 .. 20 => -- Bad weather
                  CrewIndex := FindMember(Pilot);
                  if CrewIndex > 0 then
                     AddMessage
                       ("Sudden bad weather makes your travel takes longer.",
                        OtherMessage,
                        3);
                     TimePassed :=
                       60 -
                       GetSkillLevel
                         (PlayerShip.Crew(CrewIndex),
                          PilotingSkill);
                     if TimePassed < 1 then
                        TimePassed := 1;
                     end if;
                     GainExp(1, PilotingSkill, CrewIndex);
                     UpdateCargo
                       (PlayerShip,
                        FindProtoItem(ItemType => FuelType),
                        CountFuelNeeded);
                     UpdateGame(TimePassed);
                  end if;
               when 21 .. 23 => -- Friendly trader
                  Events_List.Append
                  (New_Item =>
                     (Trader,
                      PlayerShip.SkyX,
                      PlayerShip.SkyY,
                      GetRandom(30, 45),
                      Traders
                        (GetRandom(Traders.First_Index, Traders.Last_Index))));
                  SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex :=
                    Events_List.Last_Index;
                  AddMessage("You meet friendly trader.", OtherMessage);
                  GainPerception;
                  UpdateOrders(PlayerShip);
               when 24 .. 30 => -- Friendly ship
                  Events_List.Append
                  (New_Item =>
                     (FriendlyShip,
                      PlayerShip.SkyX,
                      PlayerShip.SkyY,
                      GetRandom(30, 45),
                      FriendlyShips
                        (GetRandom
                           (FriendlyShips.First_Index,
                            FriendlyShips.Last_Index))));
                  SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex :=
                    Events_List.Last_Index;
                  AddMessage("You spotted friendly ship.", OtherMessage);
                  GainPerception;
                  UpdateOrders(PlayerShip);
               when others => -- Combat
                  GenerateEnemies;
                  Events_List.Append
                  (New_Item =>
                     (EnemyShip,
                      PlayerShip.SkyX,
                      PlayerShip.SkyY,
                      GetRandom(30, 45),
                      Enemies
                        (GetRandom(Enemies.First_Index, Enemies.Last_Index))));
                  SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex :=
                    Events_List.Last_Index;
                  return StartCombat(Events_List(Events_List.Last_Index).Data);
            end case;
         else
            if SkyBases(BaseIndex).Population = 0 then
               if Roll < 6 and
                 PlayerShip.Speed /=
                   DOCKED then -- Change owner of abandoned base
                  RecoverBase(BaseIndex);
               end if;
               return False;
            end if;
            if PlayerShip.Speed /= DOCKED then
               if Roll in 21 .. 30 and
                 SkyBases(BaseIndex).Reputation(1) = -100 then
                  Roll := 31;
               end if;
               case Roll is
                  when 1 .. 20 => -- Base is attacked
                     GenerateEnemies;
                     Events_List.Append
                     (New_Item =>
                        (AttackOnBase,
                         PlayerShip.SkyX,
                         PlayerShip.SkyY,
                         GetRandom(60, 90),
                         Enemies
                           (GetRandom
                              (Enemies.First_Index,
                               Enemies.Last_Index))));
                     AddMessage
                       ("You can't dock to base now, because base is under attack. You can help defend it.",
                        OtherMessage);
                     return StartCombat
                         (Events_List(Events_List.Last_Index).Data);
                  when 21 => -- Disease in base
                     Events_List.Append
                     (New_Item =>
                        (Disease,
                         PlayerShip.SkyX,
                         PlayerShip.SkyY,
                         GetRandom(10080, 12000),
                         1));
                     AddMessage
                       ("You can't dock to base now, it is closed due to disease.",
                        OtherMessage);
                  when 22 .. 30 => -- Double price for item in base
                     loop
                        ItemIndex :=
                          GetRandom
                            (Items_List.First_Index,
                             Items_List.Last_Index);
                        exit when Items_List(ItemIndex).Prices(1) > 0;
                     end loop;
                     Events_List.Append
                     (New_Item =>
                        (DoublePrice,
                         PlayerShip.SkyX,
                         PlayerShip.SkyY,
                         GetRandom(1440, 2880),
                         ItemIndex));
                  when others => -- Full docks or enemy patrol
                     if Roll in 20 .. 40 and
                       not Factions_List(SkyBases(BaseIndex).Owner)
                         .Friendly then
                        GenerateEnemies
                          (Factions_List(SkyBases(BaseIndex).Owner).Index);
                        Events_List.Append
                        (New_Item =>
                           (EnemyPatrol,
                            PlayerShip.SkyX,
                            PlayerShip.SkyY,
                            GetRandom(30, 45),
                            Enemies
                              (GetRandom
                                 (Enemies.First_Index,
                                  Enemies.Last_Index))));
                        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex :=
                          Events_List.Last_Index;
                        return StartCombat
                            (Events_List(Events_List.Last_Index).Data);
                     end if;
                     Events_List.Append
                     (New_Item =>
                        (FullDocks,
                         PlayerShip.SkyX,
                         PlayerShip.SkyY,
                         GetRandom(15, 30),
                         1));
                     AddMessage
                       ("You can't dock to base now, because its docks are full.",
                        OtherMessage);
               end case;
               SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex :=
                 Events_List.Last_Index;
            else
               if Roll < 5 and
                 PlayerShip.Crew.Last_Index > 1 then -- Brawl in base
                  Roll2 := GetRandom(2, PlayerShip.Crew.Last_Index);
                  Injuries := GetRandom(1, 10);
                  if Injuries > PlayerShip.Crew(Roll2).Health then
                     Injuries := PlayerShip.Crew(Roll2).Health;
                  end if;
                  PlayerShip.Crew(Roll2).Health :=
                    PlayerShip.Crew(Roll2).Health - Injuries;
                  AddMessage
                    (To_String(PlayerShip.Crew(Roll2).Name) &
                     " was injured in brawl in base.",
                     OtherMessage,
                     3);
                  if PlayerShip.Crew(Roll2).Health = 0 then
                     Death
                       (Roll2,
                        To_Unbounded_String("injuries in brawl in base"),
                        PlayerShip);
                  end if;
               elsif Roll > 4 and Roll < 10 then -- Lost cargo in base
                  Roll2 := GetRandom(1, PlayerShip.Cargo.Last_Index);
                  LostCargo := GetRandom(1, 10);
                  if LostCargo > PlayerShip.Cargo(Roll2).Amount then
                     LostCargo := PlayerShip.Cargo(Roll2).Amount;
                  end if;
                  AddMessage
                    ("During checking ship cargo, you noticed that you lost" &
                     Positive'Image(LostCargo) &
                     " " &
                     GetItemName(PlayerShip.Cargo(Roll2)) &
                     ".",
                     OtherMessage,
                     3);
                  UpdateCargo
                    (Ship => PlayerShip,
                     Amount => (0 - LostCargo),
                     CargoIndex => Roll2);
               end if;
            end if;
         end if;
      end if;
      return False;
   end CheckForEvent;

   procedure UpdateEvents(Minutes: Positive) is
      CurrentIndex: Positive := Events_List.First_Index;
      NewTime: Integer;
      EventsAmount: constant Natural := Natural(Events_List.Length);
      PopulationLost, BaseIndex: Positive;
   begin
      if EventsAmount = 0 then
         return;
      end if;
      while CurrentIndex <= Events_List.Last_Index loop
         NewTime := Events_List(CurrentIndex).Time - Minutes;
         if NewTime < 1 then
            if
              (Events_List(CurrentIndex).EType = Disease or
               Events_List(CurrentIndex).EType = AttackOnBase) and
              GetRandom(1, 100) < 10 then
               BaseIndex :=
                 SkyMap
                   (Events_List(CurrentIndex).SkyX,
                    Events_List(CurrentIndex).SkyY)
                   .BaseIndex;
               PopulationLost := GetRandom(1, 10);
               if PopulationLost > SkyBases(BaseIndex).Population then
                  PopulationLost := SkyBases(BaseIndex).Population;
                  SkyBases(BaseIndex).Reputation := (0, 0);
               end if;
               SkyBases(BaseIndex).Population :=
                 SkyBases(BaseIndex).Population - PopulationLost;
            end if;
            SkyMap
              (Events_List(CurrentIndex).SkyX,
               Events_List(CurrentIndex).SkyY)
              .EventIndex :=
              0;
            Events_List.Delete(Index => CurrentIndex);
         else
            Events_List(CurrentIndex).Time := NewTime;
            CurrentIndex := CurrentIndex + 1;
         end if;
      end loop;
      if EventsAmount > Natural(Events_List.Length) then
         for I in Events_List.First_Index .. Events_List.Last_Index loop
            SkyMap(Events_List(I).SkyX, Events_List(I).SkyY).EventIndex := I;
         end loop;
      end if;
   end UpdateEvents;

   procedure DeleteEvent(EventIndex: Positive) is
   begin
      SkyMap(Events_List(EventIndex).SkyX, Events_List(EventIndex).SkyY)
        .EventIndex :=
        0;
      Events_List.Delete(Index => EventIndex);
      for I in Events_List.First_Index .. Events_List.Last_Index loop
         SkyMap(Events_List(I).SkyX, Events_List(I).SkyY).EventIndex := I;
      end loop;
   end DeleteEvent;

   procedure GenerateTraders is
      TraderIndex: Positive;
   begin
      TraderIndex := ProtoShips_List.First_Index;
      for Ship of ProtoShips_List loop
         if Index(Ship.Name, To_String(TradersName)) > 0 then
            Traders.Append(New_Item => TraderIndex);
         end if;
         TraderIndex := TraderIndex + 1;
      end loop;
      TraderIndex := ProtoShips_List.First_Index;
      for Ship of ProtoShips_List loop
         if Factions_List(Ship.Owner).Friendly and
           Ship.Index /= PlayerShipIndex then
            FriendlyShips.Append(New_Item => TraderIndex);
         end if;
         TraderIndex := TraderIndex + 1;
      end loop;
   end GenerateTraders;

   procedure RecoverBase(BaseIndex: Positive) is
      FactionRoll: constant Positive := GetRandom(1, 100);
   begin
      for I in Factions_List.Iterate loop
         if (FactionRoll = Factions_List(I).SpawnChance(1)) or
           (FactionRoll > Factions_List(I).SpawnChance(1) and
            FactionRoll <= Factions_List(I).SpawnChance(2)) then
            SkyBases(BaseIndex).Owner := Factions_Container.To_Index(I);
            if Factions_List(I).Reputation(2) = 0 then
               SkyBases(BaseIndex).Reputation(1) :=
                 Factions_List(I).Reputation(1);
            else
               SkyBases(BaseIndex).Reputation(1) :=
                 GetRandom
                   (Factions_List(I).Reputation(1),
                    Factions_List(I).Reputation(2));
            end if;
            exit;
         end if;
      end loop;
      SkyBases(BaseIndex).Population := GetRandom(2, 50);
      SkyBases(BaseIndex).Visited := (0, 0, 0, 0, 0);
      SkyBases(BaseIndex).RecruitDate := (0, 0, 0, 0, 0);
      SkyBases(BaseIndex).MissionsDate := (0, 0, 0, 0, 0);
      AddMessage
        ("Base " & To_String(SkyBases(BaseIndex).Name) & " have new owner.",
         OtherMessage,
         5);
   end RecoverBase;

end Events;
