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

with Crew; use Crew;
with Messages; use Messages;
with ShipModules; use ShipModules;
with Items; use Items;
with Statistics; use Statistics;
with Events; use Events;
with Maps; use Maps;
with Bases; use Bases;
with Missions; use Missions;
with Ships.Cargo; use Ships.Cargo;
with Ships.Crew; use Ships.Crew;
with Ships.Movement; use Ships.Movement;
with Utils; use Utils;
with Log; use Log;
with Goals; use Goals;
with Game; use Game;
with Factions; use Factions;

package body Combat is

   FactionName: Unbounded_String;

   function StartCombat
     (EnemyIndex: Positive;
      NewCombat: Boolean := True) return Boolean is
      EnemyShip: ShipRecord;
      PlayerPerception, EnemyPerception: Natural := 0;
      function CountPerception(Spotter, Spotted: ShipRecord) return Natural is
         Result: Natural := 0;
      begin
         for I in Spotter.Crew.Iterate loop
            case Spotter.Crew(I).Order is
               when Pilot =>
                  Result :=
                    Result + GetSkillLevel(Spotter.Crew(I), PerceptionSkill);
                  if Spotter = PlayerShip then
                     GainExp(1, PerceptionSkill, Crew_Container.To_Index(I));
                  end if;
               when Gunner =>
                  Result :=
                    Result + GetSkillLevel(Spotter.Crew(I), PerceptionSkill);
                  if Spotter = PlayerShip then
                     GainExp(1, PerceptionSkill, Crew_Container.To_Index(I));
                  end if;
               when others =>
                  null;
            end case;
         end loop;
         for Module of Spotted.Modules loop
            if Modules_List(Module.ProtoIndex).MType = HULL then
               Result := Result + Module.Data(2);
               exit;
            end if;
         end loop;
         return Result;
      end CountPerception;
   begin
      EnemyShipIndex := EnemyIndex;
      FactionName := Factions_List(ProtoShips_List(EnemyIndex).Owner).Name;
      HarpoonDuration := 0;
      BoardingOrders.Clear;
      EnemyShip :=
        CreateShip
          (EnemyIndex,
           Null_Unbounded_String,
           PlayerShip.SkyX,
           PlayerShip.SkyY,
           FULL_SPEED);
      Enemy :=
        (Ship => EnemyShip,
         Accuracy => 0,
         Distance => 10000,
         CombatAI => ProtoShips_List(EnemyIndex).CombatAI,
         Evasion => 0,
         Loot => 0,
         Perception => 0,
         HarpoonDuration => 0);
      if ProtoShips_List(EnemyIndex).Accuracy(2) = 0 then
         Enemy.Accuracy := ProtoShips_List(EnemyIndex).Accuracy(1);
      else
         Enemy.Accuracy :=
           GetRandom
             (ProtoShips_List(EnemyIndex).Accuracy(1),
              ProtoShips_List(EnemyIndex).Accuracy(2));
      end if;
      if ProtoShips_List(EnemyIndex).Evasion(2) = 0 then
         Enemy.Evasion := ProtoShips_List(EnemyIndex).Evasion(1);
      else
         Enemy.Evasion :=
           GetRandom
             (ProtoShips_List(EnemyIndex).Evasion(1),
              ProtoShips_List(EnemyIndex).Evasion(2));
      end if;
      if ProtoShips_List(EnemyIndex).Perception(2) = 0 then
         Enemy.Perception := ProtoShips_List(EnemyIndex).Perception(1);
      else
         Enemy.Perception :=
           GetRandom
             (ProtoShips_List(EnemyIndex).Perception(1),
              ProtoShips_List(EnemyIndex).Perception(2));
      end if;
      if ProtoShips_List(EnemyIndex).Loot(2) = 0 then
         Enemy.Loot := ProtoShips_List(EnemyIndex).Loot(1);
      else
         Enemy.Loot :=
           GetRandom
             (ProtoShips_List(EnemyIndex).Loot(1),
              ProtoShips_List(EnemyIndex).Loot(2));
      end if;
      PilotOrder := 2;
      EngineerOrder := 3;
      EndCombat := False;
      EnemyName :=
        GenerateShipName
          (Factions_List(ProtoShips_List(EnemyIndex).Owner).Index);
      MessagesStarts := GetLastMessageIndex + 1;
      Guns.Clear;
      for I in PlayerShip.Modules.Iterate loop
         if
           (Modules_List(PlayerShip.Modules(I).ProtoIndex).MType = GUN or
            Modules_List(PlayerShip.Modules(I).ProtoIndex).MType =
              HARPOON_GUN) and
           PlayerShip.Modules(I).Durability > 0 then
            Guns.Append(New_Item => (Modules_Container.To_Index(I), 1));
         end if;
      end loop;
      if NewCombat then
         PlayerPerception := CountPerception(PlayerShip, Enemy.Ship);
         if Enemy.Perception > 0 then
            EnemyPerception := Enemy.Perception;
         else
            EnemyPerception := CountPerception(Enemy.Ship, PlayerShip);
         end if;
         if (PlayerPerception + GetRandom(1, 50)) >
           (EnemyPerception + GetRandom(1, 50)) then
            AddMessage
              ("You spotted " & To_String(Enemy.Ship.Name) & ".",
               OtherMessage);
         else
            if RealSpeed(PlayerShip) < RealSpeed(Enemy.Ship) then
               OldSpeed := PlayerShip.Speed;
               LogMessage
                 ("You were attacked by " & To_String(Enemy.Ship.Name),
                  Log.Combat);
               return True;
            end if;
            AddMessage
              ("You spotted " & To_String(Enemy.Ship.Name) & ".",
               OtherMessage);
         end if;
         return False;
      end if;
      LogMessage
        ("Started combat with " & To_String(Enemy.Ship.Name),
         Log.Combat);
      return True;
   end StartCombat;

   procedure CombatTurn is
      AccuracyBonus, EvadeBonus: Integer := 0;
      PilotIndex,
      EngineerIndex,
      EnemyWeaponIndex,
      EnemyAmmoIndex,
      EnemyPilotIndex: Natural :=
        0;
      DistanceTraveled, SpeedBonus: Integer;
      ShootMessage, Message: Unbounded_String;
      EnemyPilotOrder: Positive := 2;
      HaveFuel: Boolean := False;
      DamageRange: Positive := 10000;
      FreeSpace: Integer := 0;
      procedure Attack(Ship, EnemyShip: in out ShipRecord) is
         GunnerIndex, Shoots, AmmoIndex, ArmorIndex, WeaponIndex: Natural;
         GunnerOrder: Positive;
         HitChance, HitLocation, CurrentAccuracyBonus: Integer;
         type DamageFactor is digits 2 range 0.0 .. 1.0;
         Damage: DamageFactor := 0.0;
         WeaponDamage: Integer;
         DeathReason: Unbounded_String;
         EnemyNameOwner: constant Unbounded_String :=
           EnemyName &
           To_Unbounded_String(" (") &
           FactionName &
           To_Unbounded_String(")");
         procedure RemoveGun(ModuleIndex: Positive) is
         begin
            if EnemyShip.Modules(ModuleIndex).Owner > 0 then
               Death
                 (EnemyShip.Modules(ModuleIndex).Owner,
                  DeathReason,
                  EnemyShip);
            end if;
            if EnemyShip = PlayerShip then
               for J in Guns.First_Index .. Guns.Last_Index loop
                  if Guns(J)(1) = ModuleIndex then
                     Guns.Delete(Index => J);
                     exit;
                  end if;
               end loop;
            end if;
         end RemoveGun;
      begin
         if Ship = PlayerShip then
            LogMessage("Player's round.", Log.Combat);
         else
            LogMessage("Enemy's round.", Log.Combat);
         end if;
         Attack_Loop:
         for K in Ship.Modules.Iterate loop
            if Ship.Modules(K).Durability > 0 and
              (Modules_List(Ship.Modules(K).ProtoIndex).MType = GUN or
               Modules_List(Ship.Modules(K).ProtoIndex).MType =
                 BATTERING_RAM or
               Modules_List(Ship.Modules(K).ProtoIndex).MType =
                 HARPOON_GUN) then
               GunnerIndex := 0;
               AmmoIndex := 0;
               if
                 (Modules_List(Ship.Modules(K).ProtoIndex).MType = GUN or
                  Modules_List(Ship.Modules(K).ProtoIndex).MType =
                    HARPOON_GUN) then
                  GunnerIndex := Ship.Modules(K).Owner;
                  LogMessage
                    ("Gunner index:" & Natural'Image(GunnerIndex) & ".",
                     Log.Combat);
                  if Ship = PlayerShip then
                     if GunnerIndex = 0 then
                        Shoots := 0;
                     else
                        for Gun of Guns loop
                           if Gun(1) = Modules_Container.To_Index(K) then
                              GunnerOrder := Gun(2);
                              exit;
                           end if;
                        end loop;
                        if Ship.Crew(GunnerIndex).Order /= Gunner then
                           GunnerOrder := 1;
                        end if;
                        case GunnerOrder is
                           when 2 =>
                              CurrentAccuracyBonus := AccuracyBonus + 20;
                              Shoots := 2;
                           when 3 =>
                              Shoots := 4;
                           when 4 =>
                              CurrentAccuracyBonus := AccuracyBonus - 10;
                              Shoots := 2;
                           when 5 =>
                              CurrentAccuracyBonus := AccuracyBonus - 20;
                              Shoots := 2;
                           when 6 =>
                              Shoots := 2;
                           when others =>
                              Shoots := 0;
                        end case;
                     end if;
                  else
                     Shoots := 2;
                     if Ship.Crew.Length > 0 and GunnerIndex = 0 then
                        Shoots := 0;
                     end if;
                  end if;
                  if Ship.Modules(K).Data(1) >= Ship.Cargo.First_Index and
                    Ship.Modules(K).Data(1) <= Ship.Cargo.Last_Index then
                     if Items_List
                         (Ship.Cargo(Ship.Modules(K).Data(1)).ProtoIndex)
                         .IType =
                       Items_Types
                         (Modules_List(Ship.Modules(K).ProtoIndex).Value) then
                        AmmoIndex := Ship.Modules(K).Data(1);
                     end if;
                  end if;
                  if AmmoIndex = 0 then
                     for I in Items_List.Iterate loop
                        if Items_List(I).IType =
                          Items_Types
                            (Modules_List(Ship.Modules(K).ProtoIndex)
                               .Value) then
                           for J in Ship.Cargo.Iterate loop
                              if Ship.Cargo(J).ProtoIndex =
                                Objects_Container.To_Index(I) then
                                 AmmoIndex := Inventory_Container.To_Index(J);
                                 Ship.Modules(K).Data(1) := AmmoIndex;
                                 exit;
                              end if;
                           end loop;
                           exit when AmmoIndex > 0;
                        end if;
                     end loop;
                  end if;
                  if AmmoIndex = 0 then
                     if Ship = PlayerShip then
                        AddMessage
                          ("You don't have ammo to " &
                           To_String(Ship.Modules(K).Name) &
                           "!",
                           CombatMessage,
                           3);
                     end if;
                     Shoots := 0;
                  elsif Ship.Cargo(AmmoIndex).Amount < Shoots then
                     Shoots := Ship.Cargo(AmmoIndex).Amount;
                  end if;
                  if Enemy.Distance > 5000 then
                     Shoots := 0;
                  end if;
                  if Modules_List(Ship.Modules(K).ProtoIndex).MType =
                    HARPOON_GUN and
                    Shoots > 0 then
                     Shoots := 1;
                     if Enemy.Distance > 2000 then
                        Shoots := 0;
                     end if;
                     for Module of EnemyShip.Modules loop
                        if Modules_List(Module.ProtoIndex).MType = ARMOR and
                          Module.Durability > 0 then
                           Shoots := 0;
                           exit;
                        end if;
                     end loop;
                  end if;
               else
                  if Enemy.Distance > 100 then
                     Shoots := 0;
                  else
                     Shoots := 1;
                  end if;
               end if;
               if Shoots > 0 then
                  if Ship = PlayerShip then
                     HitChance := CurrentAccuracyBonus - Enemy.Evasion;
                  else
                     HitChance := Enemy.Accuracy - EvadeBonus;
                  end if;
                  if GunnerIndex > 0 then
                     HitChance :=
                       HitChance +
                       GetSkillLevel(Ship.Crew(GunnerIndex), GunnerySkill);
                  end if;
                  if HitChance < -48 then
                     HitChance := -48;
                  end if;
                  LogMessage
                    ("Player Accuracy:" &
                     Integer'Image(CurrentAccuracyBonus) &
                     " Player Evasion:" &
                     Integer'Image(EvadeBonus),
                     Log.Combat);
                  LogMessage
                    ("Enemy Evasion:" &
                     Integer'Image(Enemy.Evasion) &
                     " Enemy Accuracy:" &
                     Integer'Image(Enemy.Accuracy),
                     Log.Combat);
                  LogMessage
                    ("Chance to hit:" & Integer'Image(HitChance),
                     Log.Combat);
                  for I in 1 .. Shoots loop
                     if Modules_List(Ship.Modules(K).ProtoIndex).MType = GUN or
                       Modules_List(Ship.Modules(K).ProtoIndex).MType =
                         HARPOON_GUN then
                        if Ship = PlayerShip then
                           ShootMessage :=
                             Ship.Crew(GunnerIndex).Name &
                             To_Unbounded_String(" shoots at ") &
                             EnemyNameOwner;
                        else
                           ShootMessage :=
                             EnemyNameOwner &
                             To_Unbounded_String(" attacks you");
                        end if;
                     else
                        if Ship = PlayerShip then
                           ShootMessage :=
                             To_Unbounded_String("You ram ") & EnemyNameOwner;
                        else
                           ShootMessage :=
                             EnemyNameOwner &
                             To_Unbounded_String(" attacks you");
                        end if;
                     end if;
                     if HitChance + GetRandom(1, 50) >
                       GetRandom(1, HitChance + 50) then
                        ShootMessage :=
                          ShootMessage & To_Unbounded_String(" and hit ");
                        ArmorIndex := 0;
                        for J in
                          EnemyShip.Modules.First_Index ..
                              EnemyShip.Modules.Last_Index loop
                           if EnemyShip.Modules(J).Durability > 0 and
                             Modules_List(EnemyShip.Modules(J).ProtoIndex)
                                 .MType =
                               ARMOR then
                              ArmorIndex := J;
                              exit;
                           end if;
                        end loop;
                        if ArmorIndex > 0 then
                           HitLocation := ArmorIndex;
                        else
                           if Ship = PlayerShip then
                              if GunnerIndex > 0 and
                                GunnerOrder > 3 and
                                GunnerOrder <
                                  7 then -- aim for part of enemy ship
                                 HitLocation := 1;
                                 for J in EnemyShip.Modules.Iterate loop
                                    if
                                      ((GunnerOrder = 4 and
                                        Modules_List
                                            (EnemyShip.Modules(J).ProtoIndex)
                                            .MType =
                                          ENGINE) or
                                       (GunnerOrder = 5 and
                                        ((Modules_List
                                            (EnemyShip.Modules(J).ProtoIndex)
                                            .MType =
                                          TURRET and
                                          EnemyShip.Modules(J).Data(1) > 0) or
                                         Modules_List
                                             (EnemyShip.Modules(J).ProtoIndex)
                                             .MType =
                                           BATTERING_RAM)) or
                                       (GunnerOrder = 6 and
                                        Modules_List
                                            (EnemyShip.Modules(J).ProtoIndex)
                                            .MType =
                                          HULL)) and
                                      EnemyShip.Modules(J).Durability > 0 then
                                       HitLocation :=
                                         Modules_Container.To_Index(J);
                                       exit;
                                    end if;
                                 end loop;
                              else
                                 HitLocation :=
                                   GetRandom
                                     (Enemy.Ship.Modules.First_Index,
                                      Enemy.Ship.Modules.Last_Index);
                              end if;
                           else
                              if Enemy.CombatAI = DISARMER then
                                 HitLocation := 1;
                                 for J in EnemyShip.Modules.Iterate loop
                                    if
                                      ((Modules_List
                                          (EnemyShip.Modules(J).ProtoIndex)
                                          .MType =
                                        TURRET and
                                        EnemyShip.Modules(J).Data(1) > 0) or
                                       Modules_List
                                           (EnemyShip.Modules(J).ProtoIndex)
                                           .MType =
                                         BATTERING_RAM) and
                                      EnemyShip.Modules(J).Durability > 0 then
                                       HitLocation :=
                                         Modules_Container.To_Index(J);
                                       exit;
                                    end if;
                                 end loop;
                              else
                                 HitLocation :=
                                   GetRandom
                                     (PlayerShip.Modules.First_Index,
                                      PlayerShip.Modules.Last_Index);
                              end if;
                           end if;
                           while EnemyShip.Modules(HitLocation).Durability =
                             0 loop
                              HitLocation := HitLocation - 1;
                           end loop;
                        end if;
                        ShootMessage :=
                          ShootMessage &
                          EnemyShip.Modules(HitLocation).Name &
                          To_Unbounded_String(".");
                        Damage :=
                          1.0 -
                          DamageFactor
                            (Float(Ship.Modules(K).Durability) /
                             Float(Ship.Modules(K).MaxDurability));
                        WeaponDamage :=
                          Ship.Modules(K).Data(2) -
                          Natural
                            (Float(Ship.Modules(K).Data(2)) * Float(Damage));
                        if WeaponDamage = 0 then
                           WeaponDamage := 1;
                        end if;
                        if AmmoIndex > 0 then
                           WeaponDamage :=
                             WeaponDamage +
                             Items_List(Ship.Cargo(AmmoIndex).ProtoIndex).Value
                               (1);
                        end if;
                        if Modules_List(Ship.Modules(K).ProtoIndex).MType =
                          HARPOON_GUN then
                           for Module of EnemyShip.Modules loop
                              if Modules_List(Module.ProtoIndex).MType =
                                HULL then
                                 WeaponDamage :=
                                   WeaponDamage - (Module.Data(2) / 10);
                                 if WeaponDamage < 1 then
                                    WeaponDamage := 1;
                                 end if;
                                 exit;
                              end if;
                           end loop;
                           if Ship = PlayerShip then
                              Enemy.HarpoonDuration :=
                                Enemy.HarpoonDuration + WeaponDamage;
                           else
                              HarpoonDuration :=
                                HarpoonDuration + WeaponDamage;
                           end if;
                           WeaponDamage := 1;
                        end if;
                        if WeaponDamage >
                          EnemyShip.Modules(HitLocation).Durability then
                           WeaponDamage :=
                             EnemyShip.Modules(HitLocation).Durability;
                        end if;
                        EnemyShip.Modules(HitLocation).Durability :=
                          EnemyShip.Modules(HitLocation).Durability -
                          WeaponDamage;
                        if EnemyShip.Modules(HitLocation).Durability = 0 then
                           DeathReason :=
                             To_Unbounded_String("enemy fire in ships combat");
                           case Modules_List
                             (EnemyShip.Modules(HitLocation).ProtoIndex)
                             .MType is
                              when HULL | ENGINE =>
                                 EndCombat := True;
                                 if Ship /= PlayerShip then
                                    DeathReason :=
                                      To_Unbounded_String
                                        ("ship explosion in ships combat");
                                    Death(1, DeathReason, PlayerShip);
                                 end if;
                              when TURRET =>
                                 WeaponIndex :=
                                   EnemyShip.Modules(HitLocation).Data(1);
                                 if WeaponIndex > 0 then
                                    EnemyShip.Modules(WeaponIndex)
                                      .Durability :=
                                      0;
                                    RemoveGun(WeaponIndex);
                                 end if;
                              when GUN =>
                                 RemoveGun(HitLocation);
                              when CABIN =>
                                 if EnemyShip.Modules(HitLocation).Owner >
                                   0 then
                                    if EnemyShip.Crew
                                        (EnemyShip.Modules(HitLocation).Owner)
                                        .Order =
                                      Rest then
                                       Death
                                         (EnemyShip.Modules(HitLocation).Owner,
                                          DeathReason,
                                          EnemyShip);
                                    end if;
                                 end if;
                              when others =>
                                 if EnemyShip.Modules(HitLocation).Owner >
                                   0 then
                                    Death
                                      (EnemyShip.Modules(HitLocation).Owner,
                                       DeathReason,
                                       EnemyShip);
                                 end if;
                           end case;
                        end if;
                        if Ship = PlayerShip then
                           AddMessage
                             (To_String(ShootMessage),
                              CombatMessage,
                              2);
                        else
                           AddMessage
                             (To_String(ShootMessage),
                              CombatMessage,
                              1);
                        end if;
                     else
                        ShootMessage :=
                          ShootMessage & To_Unbounded_String(" and misses.");
                        if Ship = PlayerShip then
                           AddMessage
                             (To_String(ShootMessage),
                              CombatMessage,
                              4);
                        else
                           AddMessage
                             (To_String(ShootMessage),
                              CombatMessage,
                              5);
                        end if;
                     end if;
                     if AmmoIndex > 0 then
                        UpdateCargo
                          (Ship => Ship,
                           CargoIndex => AmmoIndex,
                           Amount => -1);
                     end if;
                     if Ship = PlayerShip and GunnerIndex > 0 then
                        GainExp(2, GunnerySkill, GunnerIndex);
                     end if;
                     if PlayerShip.Crew(1).Health = 0 then -- player is dead
                        EndCombat := True;
                     end if;
                     exit Attack_Loop when EndCombat;
                  end loop;
               end if;
            end if;
         end loop Attack_Loop;
      end Attack;
      procedure MeleeCombat
        (Attackers, Defenders: in out Crew_Container.Vector;
         PlayerAttack: Boolean) is
         AttackDone, Riposte: Boolean;
         AttackerIndex, DefenderIndex: Positive;
         OrderIndex: Natural;
         function CharacterAttack
           (AttackerIndex, DefenderIndex: Positive;
            PlayerAttack2: Boolean) return Boolean is
            Attacker, Defender: Member_Data;
            HitChance, Damage: Integer;
            HitLocation: constant Positive := GetRandom(3, 6);
            AttackMessage: Unbounded_String;
            LocationNames: constant array(3 .. 6) of Unbounded_String :=
              (To_Unbounded_String("head"),
               To_Unbounded_String("torso"),
               To_Unbounded_String("leg"),
               To_Unbounded_String("arm"));
            MessageColor, AttackSkill, BaseDamage: Natural;
            type DamageFactor is digits 2 range 0.0 .. 1.0;
            Wounds: DamageFactor := 0.0;
         begin
            if PlayerAttack2 then
               Attacker := PlayerShip.Crew(AttackerIndex);
               Defender := Enemy.Ship.Crew(DefenderIndex);
               AttackMessage :=
                 Attacker.Name &
                 To_Unbounded_String(" attacks ") &
                 Defender.Name &
                 To_Unbounded_String(" (") &
                 FactionName &
                 To_Unbounded_String(")");
            else
               Attacker := Enemy.Ship.Crew(AttackerIndex);
               Defender := PlayerShip.Crew(DefenderIndex);
               AttackMessage :=
                 Attacker.Name &
                 To_Unbounded_String(" (") &
                 FactionName &
                 To_Unbounded_String(")") &
                 To_Unbounded_String(" attacks ") &
                 Defender.Name;
            end if;
            BaseDamage := Attacker.Attributes(StrengthIndex)(1);
            if Attacker.Equipment(1) > 0 then
               BaseDamage :=
                 BaseDamage +
                 Items_List
                   (Attacker.Inventory(Attacker.Equipment(1)).ProtoIndex)
                   .Value
                   (2);
            end if;
         -- Count damage based on attacker wounds, fatigue, hunger and thirst
            Wounds := 1.0 - DamageFactor(Float(Attacker.Health) / 100.0);
            Damage :=
              (BaseDamage - Integer(Float(BaseDamage) * Float(Wounds)));
            if Attacker.Thirst > 40 then
               Wounds := 1.0 - DamageFactor(Float(Attacker.Thirst) / 100.0);
               Damage := Damage - (Integer(Float(BaseDamage) * Float(Wounds)));
            end if;
            if Attacker.Hunger > 80 then
               Wounds := 1.0 - DamageFactor(Float(Attacker.Hunger) / 100.0);
               Damage := Damage - (Integer(Float(BaseDamage) * Float(Wounds)));
            end if;
            if Attacker.Equipment(1) > 0 then
               AttackSkill :=
                 GetSkillLevel
                   (Attacker,
                    Items_List
                      (Attacker.Inventory(Attacker.Equipment(1)).ProtoIndex)
                      .Value
                      (3));
               HitChance := AttackSkill + GetRandom(1, 50);
            else
               HitChance :=
                 GetSkillLevel(Attacker, UnarmedSkill) + GetRandom(1, 50);
            end if;
            HitChance :=
              HitChance -
              (GetSkillLevel(Defender, DodgeSkill) + GetRandom(1, 50));
            for I in 3 .. 6 loop
               if Defender.Equipment(I) > 0 then
                  HitChance :=
                    HitChance +
                    Items_List
                      (Defender.Inventory(Defender.Equipment(I)).ProtoIndex)
                      .Value
                      (3);
               end if;
            end loop;
            if Defender.Equipment(HitLocation) > 0 then
               Damage :=
                 Damage -
                 Items_List
                   (Defender.Inventory(Defender.Equipment(HitLocation))
                      .ProtoIndex)
                   .Value
                   (2);
            end if;
            if Defender.Equipment(2) > 0 then
               Damage :=
                 Damage -
                 Items_List
                   (Defender.Inventory(Defender.Equipment(2)).ProtoIndex)
                   .Value
                   (2);
            end if;
            if Damage < 1 then
               Damage := 1;
            end if;
            -- Count damage based on damage type of weapon
            if Attacker.Equipment(1) > 0 then
               if Items_List
                   (Attacker.Inventory(Attacker.Equipment(1)).ProtoIndex)
                   .Value
                   (5) =
                 1 then -- cutting weapon
                  Damage := Integer(Float(Damage) * 1.5);
               elsif Items_List
                   (Attacker.Inventory(Attacker.Equipment(1)).ProtoIndex)
                   .Value
                   (5) =
                 2 then -- impale weapon
                  Damage := Damage * 2;
               end if;
            end if;
            if HitChance < 1 then
               AttackMessage :=
                 AttackMessage & To_Unbounded_String(" and miss.");
               if PlayerAttack then
                  MessageColor := 4;
               else
                  MessageColor := 5;
               end if;
               if not PlayerAttack then
                  GainExp(2, DodgeSkill, DefenderIndex);
                  Defender.Skills := PlayerShip.Crew(DefenderIndex).Skills;
                  Defender.Attributes :=
                    PlayerShip.Crew(DefenderIndex).Attributes;
               end if;
            else
               AttackMessage :=
                 AttackMessage &
                 To_Unbounded_String(" and hit ") &
                 LocationNames(HitLocation) &
                 To_Unbounded_String(".");
               if PlayerAttack2 then
                  MessageColor := 2;
               else
                  MessageColor := 1;
               end if;
               if Attacker.Equipment(1) > 0 then
                  DamageItem
                    (Attacker.Inventory,
                     Attacker.Equipment(1),
                     AttackSkill,
                     AttackerIndex);
               end if;
               if Defender.Equipment(HitLocation) > 0 then
                  DamageItem
                    (Defender.Inventory,
                     Defender.Equipment(HitLocation),
                     0,
                     DefenderIndex);
               end if;
               if PlayerAttack2 then
                  if Attacker.Equipment(1) > 0 then
                     GainExp
                       (2,
                        Items_List
                          (Attacker.Inventory(Attacker.Equipment(1))
                             .ProtoIndex)
                          .Value
                          (3),
                        AttackerIndex);
                  else
                     GainExp(2, UnarmedSkill, AttackerIndex);
                  end if;
                  Attacker.Skills := PlayerShip.Crew(AttackerIndex).Skills;
                  Attacker.Attributes :=
                    PlayerShip.Crew(AttackerIndex).Attributes;
               end if;
               if Damage > Defender.Health then
                  Defender.Health := 0;
               else
                  Defender.Health := Defender.Health - Damage;
               end if;
            end if;
            AddMessage(To_String(AttackMessage), CombatMessage, MessageColor);
            Attacker.Tired := Attacker.Tired + 1;
            Defender.Tired := Defender.Tired + 1;
            if PlayerAttack2 then
               PlayerShip.Crew(AttackerIndex) := Attacker;
               Enemy.Ship.Crew(DefenderIndex) := Defender;
            else
               PlayerShip.Crew(DefenderIndex) := Defender;
               Enemy.Ship.Crew(AttackerIndex) := Attacker;
            end if;
            if Defender.Health = 0 then
               if PlayerAttack2 then
                  Death
                    (DefenderIndex,
                     Attacker.Name &
                     To_Unbounded_String(" blow in melee combat"),
                     Enemy.Ship);
                  for Order of BoardingOrders loop
                     if Order >= DefenderIndex then
                        Order := Order - 1;
                     end if;
                  end loop;
                  UpdateKilledMobs(Defender, FactionName);
                  UpdateGoal(KILL, FactionName);
                  if Enemy.Ship.Crew.Length = 0 then
                     EndCombat := True;
                  end if;
               else
                  OrderIndex := 0;
                  for I in PlayerShip.Crew.Iterate loop
                     if PlayerShip.Crew(I).Order = Boarding then
                        OrderIndex := OrderIndex + 1;
                     end if;
                     if Crew_Container.To_Index(I) = DefenderIndex then
                        BoardingOrders.Delete(Index => OrderIndex);
                        OrderIndex := OrderIndex - 1;
                        exit;
                     end if;
                  end loop;
                  Death
                    (DefenderIndex,
                     Attacker.Name &
                     To_Unbounded_String(" blow in melee combat"),
                     PlayerShip);
                  if DefenderIndex = 1 then -- Player is dead
                     EndCombat := True;
                  end if;
               end if;
               return False;
            else
               return True;
            end if;
         end CharacterAttack;
      begin
         AttackerIndex := Attackers.First_Index;
         OrderIndex := 1;
         while AttackerIndex <=
           Attackers.Last_Index loop -- Boarding party attacks first
            Riposte := True;
            if Attackers(AttackerIndex).Order = Boarding then
               AttackDone := False;
               if PlayerAttack then
                  if BoardingOrders(OrderIndex) in
                      Defenders.First_Index .. Defenders.Last_Index then
                     DefenderIndex := BoardingOrders(OrderIndex);
                     Riposte :=
                       CharacterAttack
                         (AttackerIndex,
                          DefenderIndex,
                          PlayerAttack);
                     if not EndCombat and Riposte then
                        if Enemy.Ship.Crew(DefenderIndex).Order /= Defend then
                           GiveOrders
                             (Enemy.Ship,
                              DefenderIndex,
                              Defend,
                              0,
                              False);
                        end if;
                        Riposte :=
                          CharacterAttack
                            (DefenderIndex,
                             AttackerIndex,
                             not PlayerAttack);
                     else
                        Riposte := True;
                     end if;
                     AttackDone := True;
                  elsif BoardingOrders(OrderIndex) = -1 then
                     GiveOrders(PlayerShip, AttackerIndex, Rest);
                     BoardingOrders.Delete(Index => OrderIndex);
                     OrderIndex := OrderIndex - 1;
                     AttackDone := True;
                  end if;
                  OrderIndex := OrderIndex + 1;
               end if;
               if not AttackDone then
                  for Defender in
                    Defenders.First_Index .. Defenders.Last_Index loop
                     if Defenders(Defender).Order = Defend then
                        Riposte :=
                          CharacterAttack
                            (AttackerIndex,
                             Defender,
                             PlayerAttack);
                        if not EndCombat and Riposte then
                           Riposte :=
                             CharacterAttack
                               (Defender,
                                AttackerIndex,
                                not PlayerAttack);
                        else
                           Riposte := True;
                        end if;
                        AttackDone := True;
                        exit;
                     end if;
                  end loop;
               end if;
               if not AttackDone then
                  DefenderIndex :=
                    GetRandom(Defenders.First_Index, Defenders.Last_Index);
                  if PlayerAttack then
                     GiveOrders(Enemy.Ship, DefenderIndex, Defend, 0, False);
                  else
                     GiveOrders(PlayerShip, DefenderIndex, Defend, 0, False);
                  end if;
                  Riposte :=
                    CharacterAttack
                      (AttackerIndex => AttackerIndex,
                       DefenderIndex => DefenderIndex,
                       PlayerAttack2 => PlayerAttack);
                  if not EndCombat and Riposte then
                     Riposte :=
                       CharacterAttack
                         (AttackerIndex => DefenderIndex,
                          DefenderIndex => AttackerIndex,
                          PlayerAttack2 => not PlayerAttack);
                  else
                     Riposte := True;
                  end if;
               end if;
            end if;
            exit when EndCombat;
            if Riposte then
               AttackerIndex := AttackerIndex + 1;
            end if;
         end loop;
         DefenderIndex := Defenders.First_Index;
         while DefenderIndex <= Defenders.Last_Index loop -- Defenders attacks
            Riposte := True;
            if Defenders(DefenderIndex).Order = Defend then
               for Attacker in
                 Attackers.First_Index .. Attackers.Last_Index loop
                  if Attackers(Attacker).Order = Boarding then
                     Riposte :=
                       CharacterAttack
                         (DefenderIndex,
                          Attacker,
                          not PlayerAttack);
                     if not EndCombat and Riposte then
                        Riposte :=
                          CharacterAttack
                            (Attacker,
                             DefenderIndex,
                             PlayerAttack);
                     end if;
                     exit;
                  end if;
               end loop;
            end if;
            if Riposte then
               DefenderIndex := DefenderIndex + 1;
            end if;
         end loop;
         if FindMember(Boarding) = 0 then
            UpdateOrders(Enemy.Ship);
         end if;
      end MeleeCombat;
   begin
      for I in PlayerShip.Crew.Iterate loop
         case PlayerShip.Crew(I).Order is
            when Pilot =>
               PilotIndex := Crew_Container.To_Index(I);
               GainExp(2, PilotingSkill, PilotIndex);
            when Engineer =>
               EngineerIndex := Crew_Container.To_Index(I);
               GainExp(2, EngineeringSkill, EngineerIndex);
            when others =>
               null;
         end case;
      end loop;
      EnemyPilotIndex := FindMember(Pilot, Enemy.Ship.Crew);
      if FindItem(Inventory => PlayerShip.Cargo, ItemType => FuelType) > 0 then
         HaveFuel := True;
      end if;
      if not HaveFuel then
         PilotOrder := 1;
         EngineerOrder := 1;
         if EngineerIndex = 0 and PlayerShip.Speed /= FULL_STOP then
            PlayerShip.Speed := FULL_STOP;
         end if;
      end if;
      if PilotIndex > 0 then
         case PilotOrder is
            when 1 =>
               AccuracyBonus := 20;
               EvadeBonus := -10;
            when 2 =>
               AccuracyBonus := 10;
               EvadeBonus := 0;
            when 3 =>
               AccuracyBonus := 0;
               EvadeBonus := 10;
            when 4 =>
               AccuracyBonus := -10;
               EvadeBonus := 20;
            when others =>
               null;
         end case;
         EvadeBonus :=
           EvadeBonus +
           GetSkillLevel(PlayerShip.Crew(PilotIndex), PilotingSkill);
      else
         AccuracyBonus := 20;
         EvadeBonus := -10;
      end if;
      if EnemyPilotIndex > 0 then
         AccuracyBonus :=
           AccuracyBonus -
           GetSkillLevel(Enemy.Ship.Crew(EnemyPilotIndex), PilotingSkill);
      end if;
      if EngineerIndex > 0 and HaveFuel then
         Message :=
           To_Unbounded_String(ChangeShipSpeed(ShipSpeed'Val(EngineerOrder)));
         if Length(Message) > 0 then
            AddMessage(To_String(Message), OrderMessage, 3);
         end if;
      end if;
      SpeedBonus := 20 - (RealSpeed(PlayerShip) / 100);
      if SpeedBonus < -10 then
         SpeedBonus := -10;
      end if;
      AccuracyBonus := AccuracyBonus + SpeedBonus;
      EvadeBonus := EvadeBonus - SpeedBonus;
      for I in Enemy.Ship.Modules.Iterate loop
         if Enemy.Ship.Modules(I).Durability > 0 and
           (Modules_List(Enemy.Ship.Modules(I).ProtoIndex).MType = GUN or
            Modules_List(Enemy.Ship.Modules(I).ProtoIndex).MType =
              BATTERING_RAM or
            Modules_List(Enemy.Ship.Modules(I).ProtoIndex).MType =
              HARPOON_GUN) then
            if Modules_List(Enemy.Ship.Modules(I).ProtoIndex).MType = GUN or
              Modules_List(Enemy.Ship.Modules(I).ProtoIndex).MType =
                HARPOON_GUN then
               if Modules_List(Enemy.Ship.Modules(I).ProtoIndex).MType =
                 GUN and
                 DamageRange > 5000 then
                  DamageRange := 5000;
               elsif DamageRange > 2000 then
                  DamageRange := 2000;
               end if;
               if Enemy.Ship.Modules(I).Data(1) >=
                 Enemy.Ship.Cargo.First_Index and
                 Enemy.Ship.Modules(I).Data(1) <=
                   Enemy.Ship.Cargo.Last_Index then
                  if Items_List
                      (Enemy.Ship.Cargo(Enemy.Ship.Modules(I).Data(1))
                         .ProtoIndex)
                      .IType =
                    Items_Types
                      (Modules_List(Enemy.Ship.Modules(I).ProtoIndex)
                         .Value) then
                     EnemyAmmoIndex := Enemy.Ship.Modules(I).Data(1);
                  end if;
               end if;
               if EnemyAmmoIndex = 0 then
                  for K in Items_List.Iterate loop
                     if Items_List(K).IType =
                       Items_Types
                         (Modules_List(Enemy.Ship.Modules(I).ProtoIndex)
                            .Value) then
                        for J in Enemy.Ship.Cargo.Iterate loop
                           if Enemy.Ship.Cargo(J).ProtoIndex =
                             Objects_Container.To_Index(K) then
                              EnemyAmmoIndex :=
                                Inventory_Container.To_Index(J);
                              exit;
                           end if;
                        end loop;
                        exit when EnemyAmmoIndex > 0;
                     end if;
                  end loop;
               end if;
               if EnemyAmmoIndex = 0 and
                 (Enemy.CombatAI = ATTACKER or Enemy.CombatAI = DISARMER) then
                  Enemy.CombatAI := COWARD;
                  exit;
               end if;
            elsif DamageRange > 100 then
               DamageRange := 100;
            end if;
            EnemyWeaponIndex := Modules_Container.To_Index(I);
         end if;
      end loop;
      if EnemyWeaponIndex = 0 and
        (Enemy.CombatAI = ATTACKER or Enemy.CombatAI = DISARMER) then
         Enemy.CombatAI := COWARD;
      end if;
      case Enemy.CombatAI is
         when BERSERKER =>
            if Enemy.Distance > 10 and Enemy.Ship.Speed /= FULL_SPEED then
               Enemy.Ship.Speed :=
                 ShipSpeed'Val(ShipSpeed'Pos(Enemy.Ship.Speed) + 1);
               AddMessage
                 (To_String(EnemyName) & " increases speed.",
                  CombatMessage);
               EnemyPilotOrder := 1;
            elsif Enemy.Distance <= 10 and Enemy.Ship.Speed = FULL_SPEED then
               Enemy.Ship.Speed :=
                 ShipSpeed'Val(ShipSpeed'Pos(Enemy.Ship.Speed) - 1);
               AddMessage
                 (To_String(EnemyName) & " decreases speed.",
                  CombatMessage);
               EnemyPilotOrder := 2;
            end if;
         when ATTACKER | DISARMER =>
            if Enemy.Distance > DamageRange and
              Enemy.Ship.Speed /= FULL_SPEED then
               Enemy.Ship.Speed :=
                 ShipSpeed'Val(ShipSpeed'Pos(Enemy.Ship.Speed) + 1);
               AddMessage
                 (To_String(EnemyName) & " increases speed.",
                  CombatMessage);
               EnemyPilotOrder := 1;
            elsif Enemy.Distance < DamageRange and
              Enemy.Ship.Speed > QUARTER_SPEED then
               Enemy.Ship.Speed :=
                 ShipSpeed'Val(ShipSpeed'Pos(Enemy.Ship.Speed) - 1);
               AddMessage
                 (To_String(EnemyName) & " decreases speed.",
                  CombatMessage);
               EnemyPilotOrder := 2;
            end if;
         when COWARD =>
            if Enemy.Distance < 15000 and Enemy.Ship.Speed /= FULL_SPEED then
               Enemy.Ship.Speed :=
                 ShipSpeed'Val(ShipSpeed'Pos(Enemy.Ship.Speed) + 1);
               AddMessage
                 (To_String(EnemyName) & " increases speed.",
                  CombatMessage);
            end if;
            EnemyPilotOrder := 4;
         when others =>
            null;
      end case;
      if Enemy.HarpoonDuration > 0 then
         Enemy.Ship.Speed := FULL_STOP;
         AddMessage
           (To_String(EnemyName) & " is stopped by harpoon.",
            CombatMessage);
      elsif Enemy.Ship.Speed = FULL_STOP then
         Enemy.Ship.Speed := QUARTER_SPEED;
      end if;
      if HarpoonDuration > 0 then
         PlayerShip.Speed := FULL_STOP;
         AddMessage("You are stopped by enemy harpoon.", CombatMessage);
      end if;
      case EnemyPilotOrder is
         when 1 =>
            AccuracyBonus := AccuracyBonus + 20;
            EvadeBonus := EvadeBonus - 20;
         when 2 =>
            AccuracyBonus := AccuracyBonus + 10;
            EvadeBonus := EvadeBonus - 10;
         when 3 =>
            AccuracyBonus := AccuracyBonus - 10;
            EvadeBonus := EvadeBonus + 10;
         when 4 =>
            AccuracyBonus := AccuracyBonus - 20;
            EvadeBonus := EvadeBonus + 20;
         when others =>
            null;
      end case;
      SpeedBonus := 20 - (RealSpeed(Enemy.Ship) / 100);
      if SpeedBonus < -10 then
         SpeedBonus := -10;
      end if;
      AccuracyBonus := AccuracyBonus + SpeedBonus;
      EvadeBonus := EvadeBonus - SpeedBonus;
      if EnemyPilotOrder < 4 then
         DistanceTraveled := 0 - RealSpeed(Enemy.Ship);
      else
         DistanceTraveled := RealSpeed(Enemy.Ship);
      end if;
      if PilotIndex > 0 then
         case PilotOrder is
            when 1 | 3 =>
               DistanceTraveled := DistanceTraveled - RealSpeed(PlayerShip);
            when 2 =>
               DistanceTraveled := DistanceTraveled + RealSpeed(PlayerShip);
               if DistanceTraveled > 0 and EnemyPilotOrder /= 4 then
                  DistanceTraveled := 0;
               end if;
            when 4 =>
               DistanceTraveled := DistanceTraveled + RealSpeed(PlayerShip);
            when others =>
               null;
         end case;
      else
         DistanceTraveled := DistanceTraveled - RealSpeed(PlayerShip);
      end if;
      Enemy.Distance := Enemy.Distance + DistanceTraveled;
      if Enemy.Distance < 10 then
         Enemy.Distance := 10;
      end if;
      if Enemy.Distance >= 15000 then
         if PilotOrder = 4 then
            AddMessage
              ("You escaped from " & To_String(EnemyName) & ".",
               CombatMessage);
         else
            AddMessage
              (To_String(EnemyName) & " escaped from you.",
               CombatMessage);
         end if;
         for I in PlayerShip.Crew.Iterate loop
            if PlayerShip.Crew(I).Order = Boarding then
               Death
                 (Crew_Container.To_Index(I),
                  To_Unbounded_String("enemy crew"),
                  PlayerShip,
                  False);
            end if;
         end loop;
         EndCombat := True;
         return;
      elsif Enemy.Distance < 15000 and Enemy.Distance >= 10000 then
         AccuracyBonus := AccuracyBonus - 10;
         EvadeBonus := EvadeBonus + 10;
         LogMessage("Distance: long", Log.Combat);
      elsif Enemy.Distance < 5000 and Enemy.Distance >= 1000 then
         AccuracyBonus := AccuracyBonus + 10;
         LogMessage("Distance: medium", Log.Combat);
      elsif Enemy.Distance < 1000 then
         AccuracyBonus := AccuracyBonus + 20;
         EvadeBonus := EvadeBonus - 10;
         LogMessage("Distance: short or close", Log.Combat);
      end if;
      Attack(PlayerShip, Enemy.Ship); -- Player attack
      if not EndCombat then
         Attack(Enemy.Ship, PlayerShip); -- Enemy attack
      end if;
      if not EndCombat then
         declare
            HaveBoardingParty: Boolean := False;
         begin
            for Member of PlayerShip.Crew loop
               if Member.Order = Boarding then
                  HaveBoardingParty := True;
                  exit;
               end if;
            end loop;
            for Member of Enemy.Ship.Crew loop
               if Member.Order = Boarding then
                  HaveBoardingParty := True;
                  exit;
               end if;
            end loop;
            if Enemy.HarpoonDuration > 0 or
              HarpoonDuration > 0 or
              HaveBoardingParty then
               if not EndCombat and
                 Enemy.Ship.Crew.Length >
                   0 then -- Characters combat (player boarding party)
                  MeleeCombat(PlayerShip.Crew, Enemy.Ship.Crew, True);
               end if;
               if not EndCombat and
                 Enemy.Ship.Crew.Length >
                   0 then -- Characters combat (enemy boarding party)
                  MeleeCombat(Enemy.Ship.Crew, PlayerShip.Crew, False);
               end if;
            end if;
         end;
      end if;
      if not EndCombat then
         if Enemy.HarpoonDuration > 0 then
            Enemy.HarpoonDuration := Enemy.HarpoonDuration - 1;
         end if;
         if HarpoonDuration > 0 then
            HarpoonDuration := HarpoonDuration - 1;
         end if;
         if Enemy.HarpoonDuration > 0 or
           HarpoonDuration >
             0 then -- Set defenders/boarding party on player ship
            UpdateOrders(PlayerShip, True);
         end if;
         UpdateGame(1);
      elsif PlayerShip.Crew(1).Health > 0 then
         declare
            WasBoarded: Boolean := False;
            LootAmount: Integer;
            MoneyIndex2: constant Positive := FindProtoItem(MoneyIndex);
         begin
            for I in PlayerShip.Crew.Iterate loop
               if PlayerShip.Crew(I).Order = Boarding then
                  GiveOrders(PlayerShip, Crew_Container.To_Index(I), Rest);
                  WasBoarded := True;
               elsif PlayerShip.Crew(I).Order = Defend then
                  GiveOrders(PlayerShip, Crew_Container.To_Index(I), Rest);
               end if;
            end loop;
            Enemy.Ship.Modules(1).Durability := 0;
            AddMessage(To_String(EnemyName) & " is destroyed!", CombatMessage);
            LootAmount := Enemy.Loot;
            FreeSpace := FreeCargo((0 - LootAmount));
            if FreeSpace < 0 then
               LootAmount := LootAmount + FreeSpace;
            end if;
            if LootAmount > 0 then
               AddMessage
                 ("You looted" &
                  Integer'Image(LootAmount) &
                  " " &
                  To_String(MoneyName) &
                  " from " &
                  To_String(EnemyName) &
                  ".",
                  CombatMessage);
               UpdateCargo(PlayerShip, MoneyIndex2, LootAmount);
            end if;
            FreeSpace := FreeCargo(0);
            if WasBoarded and FreeSpace > 0 then
               Message :=
                 To_Unbounded_String
                   ("Additionally, your boarding party takes from ") &
                 EnemyName &
                 To_Unbounded_String(":");
               for Item of Enemy.Ship.Cargo loop
                  LootAmount := Item.Amount / 5;
                  FreeSpace := FreeCargo((0 - LootAmount));
                  if FreeSpace < 0 then
                     LootAmount := LootAmount + FreeSpace;
                  end if;
                  if Items_List(Item.ProtoIndex).Prices(1) = 0 and
                    Item.ProtoIndex /= MoneyIndex2 then
                     LootAmount := 0;
                  end if;
                  if LootAmount > 0 then
                     if Item /= Enemy.Ship.Cargo.First_Element then
                        Message := Message & To_Unbounded_String(",");
                     end if;
                     UpdateCargo(PlayerShip, Item.ProtoIndex, LootAmount);
                     Message :=
                       Message &
                       Positive'Image(LootAmount) &
                       To_Unbounded_String(" ") &
                       Items_List(Item.ProtoIndex).Name;
                     FreeSpace := FreeCargo(0);
                     if Item = Enemy.Ship.Cargo.Last_Element or
                       FreeSpace = 0 then
                        exit;
                     end if;
                  end if;
               end loop;
               AddMessage(To_String(Message) & ".", CombatMessage);
            end if;
         end;
         Enemy.Ship.Speed := FULL_STOP;
         if SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex > 0 then
            if Events_List(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex)
                .EType =
              AttackOnBase then
               GainRep(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex, 5);
            end if;
            DeleteEvent(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex);
         end if;
         if SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).MissionIndex > 0 then
            if PlayerShip.Missions
                (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).MissionIndex)
                .MType =
              Destroy then
               if ProtoShips_List
                   (PlayerShip.Missions
                      (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).MissionIndex)
                      .Target)
                   .Name =
                 Enemy.Ship.Name then
                  UpdateMission
                    (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).MissionIndex);
               end if;
            end if;
         end if;
         if GetRandom(1, 100) < 10 then
            GainRep(Enemy.Ship.HomeBase, -100);
         end if;
         UpdateDestroyedShips(Enemy.Ship.Name);
         UpdateGoal(DESTROY, ProtoShips_List(EnemyShipIndex).Index);
         if CurrentGoal.TargetIndex /= Null_Unbounded_String then
            UpdateGoal
              (DESTROY,
               Factions_List(ProtoShips_List(EnemyShipIndex).Owner).Index);
         end if;
      end if;
   end CombatTurn;

end Combat;
