--    Copyright 2016-2017 Bartek thindil Jasicki
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
with UserInterface; use UserInterface;
with Ships; use Ships;
with Items; use Items;
with ShipModules; use ShipModules;

package body Bases.UI.Missions is

   function CountMissionsLimit return Natural is
      MissionsLimit: Natural;
   begin
      case SkyBases(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex)
        .Reputation
        (1) is
         when 0 .. 25 =>
            MissionsLimit := 1;
         when 26 .. 50 =>
            MissionsLimit := 3;
         when 51 .. 75 =>
            MissionsLimit := 5;
         when 76 .. 100 =>
            MissionsLimit := 10;
         when others =>
            MissionsLimit := 0;
      end case;
      for Mission of PlayerShip.Missions loop
         if Mission.StartBase =
           SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex then
            MissionsLimit := MissionsLimit - 1;
         end if;
      end loop;
      return MissionsLimit;
   end CountMissionsLimit;

   procedure ShowMissionInfo is
      Mission: constant Mission_Data :=
        SkyBases(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex).Missions
          (Get_Index(Current(TradeMenu)));
      InfoWindow: Window;
      CurrentLine: Line_Position := 2;
      MinutesDiff: Natural;
      MissionTime: Date_Record :=
        (Year => 0, Month => 0, Day => 0, Hour => 0, Minutes => 0);
      WindowWidth: Line_Position;
   begin
      case Mission.MType is
         when Deliver =>
            WindowWidth := 8;
         when Passenger =>
            WindowWidth := 7;
         when others =>
            WindowWidth := 6;
            Move_Cursor(Line => 9, Column => (Columns / 2));
            Clear_To_End_Of_Line;
            Move_Cursor(Line => 10, Column => (Columns / 2));
            Clear_To_End_Of_Line;
            Move_Cursor(Line => 11, Column => (Columns / 2));
            Clear_To_End_Of_Line;
            Move_Cursor(Line => 12, Column => (Columns / 2));
            Clear_To_End_Of_Line;
      end case;
      InfoWindow := Create(WindowWidth, (Columns / 2), 3, (Columns / 2));
      Box(InfoWindow);
      Move_Cursor(Win => InfoWindow, Line => 0, Column => 2);
      Add(Win => InfoWindow, Str => "[Mission info]");
      Move_Cursor(Win => InfoWindow, Line => 1, Column => 2);
      case Mission.MType is
         when Deliver =>
            Add
              (Win => InfoWindow,
               Str => "Item: " & To_String(Items_List(Mission.Target).Name));
            Move_Cursor(Win => InfoWindow, Line => 2, Column => 2);
            Add
              (Win => InfoWindow,
               Str =>
                 "Weight:" &
                 Positive'Image(Items_List(Mission.Target).Weight) &
                 " kg");
            Move_Cursor(Win => InfoWindow, Line => 3, Column => 2);
            Add
              (Win => InfoWindow,
               Str =>
                 "To base: " &
                 To_String
                   (SkyBases
                      (SkyMap(Mission.TargetX, Mission.TargetY).BaseIndex)
                      .Name));
            CurrentLine := 4;
         when Patrol =>
            Add(Win => InfoWindow, Str => "Patrol selected area");
         when Destroy =>
            Add
              (Win => InfoWindow,
               Str =>
                 "Target: " & To_String(ProtoShips_List(Mission.Target).Name));
         when Explore =>
            Add(Win => InfoWindow, Str => "Explore selected area");
         when Passenger =>
            Add
              (Win => InfoWindow,
               Str =>
                 "Needed cabin: " &
                 To_String(Modules_List(Mission.Target).Name));
            Move_Cursor(Win => InfoWindow, Line => 2, Column => 2);
            Add
              (Win => InfoWindow,
               Str =>
                 "To base: " &
                 To_String
                   (SkyBases
                      (SkyMap(Mission.TargetX, Mission.TargetY).BaseIndex)
                      .Name));
            CurrentLine := 3;
      end case;
      Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 2);
      Add
        (Win => InfoWindow,
         Str =>
           "Distance:" &
           Integer'Image(CountDistance(Mission.TargetX, Mission.TargetY)));
      MinutesDiff := Mission.Time;
      while MinutesDiff > 0 loop
         if MinutesDiff >= 518400 then
            MissionTime.Year := MissionTime.Year + 1;
            MinutesDiff := MinutesDiff - 518400;
         elsif MinutesDiff >= 43200 then
            MissionTime.Month := MissionTime.Month + 1;
            MinutesDiff := MinutesDiff - 43200;
         elsif MinutesDiff >= 1440 then
            MissionTime.Day := MissionTime.Day + 1;
            MinutesDiff := MinutesDiff - 1440;
         elsif MinutesDiff >= 60 then
            MissionTime.Hour := MissionTime.Hour + 1;
            MinutesDiff := MinutesDiff - 60;
         else
            MissionTime.Minutes := MinutesDiff;
            MinutesDiff := 0;
         end if;
      end loop;
      CurrentLine := CurrentLine + 1;
      Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 2);
      Add(Win => InfoWindow, Str => "Time limit:");
      if MissionTime.Year > 0 then
         Add(Win => InfoWindow, Str => Positive'Image(MissionTime.Year) & "y");
      end if;
      if MissionTime.Month > 0 then
         Add
           (Win => InfoWindow,
            Str => Positive'Image(MissionTime.Month) & "m");
      end if;
      if MissionTime.Day > 0 then
         Add(Win => InfoWindow, Str => Positive'Image(MissionTime.Day) & "d");
      end if;
      if MissionTime.Hour > 0 then
         Add(Win => InfoWindow, Str => Positive'Image(MissionTime.Hour) & "h");
      end if;
      if MissionTime.Minutes > 0 then
         Add
           (Win => InfoWindow,
            Str => Positive'Image(MissionTime.Minutes) & "mins");
      end if;
      CurrentLine := CurrentLine + 1;
      Move_Cursor(Win => InfoWindow, Line => CurrentLine, Column => 2);
      Add
        (Win => InfoWindow,
         Str =>
           "Reward:" &
           Positive'Image(Mission.Reward) &
           " " &
           To_String(MoneyName));
      CurrentLine := WindowWidth + 3;
      Move_Cursor(Line => CurrentLine, Column => (Columns / 2));
      Add
        (Str =>
           "You can take" &
           Natural'Image(CountMissionsLimit) &
           " more missions in this base.");
      CurrentLine := CurrentLine + 1;
      Move_Cursor(Line => CurrentLine, Column => (Columns / 2));
      Add(Str => "ENTER to accept selected mission.");
      Change_Attributes
        (Line => CurrentLine,
         Column => (Columns / 2),
         Count => 5,
         Color => 1);
      Refresh;
      Refresh(InfoWindow);
      Delete(InfoWindow);
   end ShowMissionInfo;

   procedure ShowBaseMissions is
      BaseIndex: constant Positive :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      Missions_Items: constant Item_Array_Access :=
        new Item_Array(1 .. (SkyBases(BaseIndex).Missions.Last_Index + 1));
      MenuHeight: Line_Position;
      MenuLength: Column_Position;

   begin
      if SkyBases(BaseIndex).Missions.Length = 0 then
         if TradeMenu /= Null_Menu then
            Post(TradeMenu, False);
            Delete(TradeMenu);
         end if;
         Move_Cursor(Line => (Lines / 3), Column => (Columns / 3));
         Add(Str => "No available missions in this base.");
         Refresh;
         return;
      end if;
      if CountMissionsLimit < 1 then
         if TradeMenu /= Null_Menu then
            Post(TradeMenu, False);
            Delete(TradeMenu);
         end if;
         Move_Cursor(Line => (Lines / 3), Column => (Columns / 3));
         Add(Str => "You can't take any more missions from this base.");
         Refresh;
         return;
      end if;
      for I in
        SkyBases(BaseIndex).Missions.First_Index ..
            SkyBases(BaseIndex).Missions.Last_Index loop
         case SkyBases(BaseIndex).Missions(I).MType is
            when Deliver =>
               Missions_Items.all(I) := New_Item("Deliver item to base");
            when Patrol =>
               Missions_Items.all(I) := New_Item("Patrol area");
            when Destroy =>
               Missions_Items.all(I) := New_Item("Destroy ship");
            when Explore =>
               Missions_Items.all(I) := New_Item("Explore area");
            when Passenger =>
               Missions_Items.all(I) :=
                 New_Item("Transport passenger to base");
         end case;
      end loop;
      Missions_Items.all(Missions_Items'Last) := Null_Item;
      TradeMenu := New_Menu(Missions_Items);
      Set_Format(TradeMenu, Lines - 10, 1);
      Set_Mark(TradeMenu, "");
      Scale(TradeMenu, MenuHeight, MenuLength);
      MenuWindow := Create(MenuHeight, MenuLength, 3, 2);
      Set_Window(TradeMenu, MenuWindow);
      Set_Sub_Window
        (TradeMenu,
         Derived_Window(MenuWindow, MenuHeight, MenuLength, 0, 0));
      Post(TradeMenu);
      ShowMissionInfo;
      Refresh(MenuWindow);
   end ShowBaseMissions;

   function BaseMissionsKeys(Key: Key_Code) return GameStates is
      Result: Menus.Driver_Result := Request_Denied;
   begin
      if TradeMenu /= Null_Menu then
         case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
               if TradeMenu /= Null_Menu then
                  Post(TradeMenu, False);
                  Delete(TradeMenu);
               end if;
               DrawGame(Sky_Map_View);
               return Sky_Map_View;
            when 56 | KEY_UP => -- Select previous recipe to buy
               Result := Driver(TradeMenu, M_Up_Item);
               if Result = Request_Denied then
                  Result := Driver(TradeMenu, M_Last_Item);
               end if;
            when 50 | KEY_DOWN => -- Select next recipe to buy
               Result := Driver(TradeMenu, M_Down_Item);
               if Result = Request_Denied then
                  Result := Driver(TradeMenu, M_First_Item);
               end if;
            when 10 => -- Accept mission
               AcceptMission(Get_Index(Current(TradeMenu)));
               DrawGame(BaseMissions_View);
            when others =>
               Result := Driver(TradeMenu, Key);
               if Result /= Menu_Ok then
                  Result := Driver(TradeMenu, M_Clear_Pattern);
                  Result := Driver(TradeMenu, Key);
               end if;
         end case;
         if Result = Menu_Ok then
            ShowMissionInfo;
            Refresh(MenuWindow);
         end if;
      else
         case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
               DrawGame(Sky_Map_View);
               return Sky_Map_View;
            when others =>
               null;
         end case;
      end if;
      return BaseMissions_View;
   end BaseMissionsKeys;

end Bases.UI.Missions;
