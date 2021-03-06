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

with Ada.Directories; use Ada.Directories;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with DOM.Core; use DOM.Core;
with DOM.Core.Documents; use DOM.Core.Documents;
with DOM.Core.Nodes; use DOM.Core.Nodes;
with DOM.Core.Elements; use DOM.Core.Elements;
with DOM.Readers; use DOM.Readers;
with Input_Sources.File; use Input_Sources.File;
with Game; use Game;
with Log; use Log;
with Ships; use Ships;
with Crafts; use Crafts;
with Items; use Items;
with Utils; use Utils;
with Statistics; use Statistics;
with Messages; use Messages;
with Missions; use Missions;
with Factions; use Factions;

package body Goals is

   procedure LoadGoals is
      TempRecord: Goal_Data;
      Files: Search_Type;
      FoundFile: Directory_Entry_Type;
      GoalsFile: File_Input;
      Reader: Tree_Reader;
      NodesList: Node_List;
      GoalsData: Document;
   begin
      if Goals_List.Length > 0 then
         return;
      end if;
      if not Exists(To_String(DataDirectory) & "goals" & Dir_Separator) then
         raise Goals_Directory_Not_Found;
      end if;
      Start_Search
        (Files,
         To_String(DataDirectory) & "goals" & Dir_Separator,
         "*.dat");
      if not More_Entries(Files) then
         raise Goals_Files_Not_Found;
      end if;
      while More_Entries(Files) loop
         Get_Next_Entry(Files, FoundFile);
         TempRecord :=
           (Index => Null_Unbounded_String,
            GType => RANDOM,
            Amount => 0,
            TargetIndex => Null_Unbounded_String,
            Multiplier => 1);
         LogMessage("Loading goals file: " & Full_Name(FoundFile), Everything);
         Open(Full_Name(FoundFile), GoalsFile);
         Parse(Reader, GoalsFile);
         Close(GoalsFile);
         GoalsData := Get_Tree(Reader);
         NodesList :=
           DOM.Core.Documents.Get_Elements_By_Tag_Name(GoalsData, "goal");
         for I in 0 .. Length(NodesList) - 1 loop
            TempRecord.Index :=
              To_Unbounded_String(Get_Attribute(Item(NodesList, I), "index"));
            TempRecord.GType :=
              GoalTypes'Value(Get_Attribute(Item(NodesList, I), "type"));
            TempRecord.Amount :=
              Natural'Value(Get_Attribute(Item(NodesList, I), "amount"));
            if Get_Attribute(Item(NodesList, I), "target") /= "" then
               TempRecord.TargetIndex :=
                 To_Unbounded_String
                   (Get_Attribute(Item(NodesList, I), "target"));
            end if;
            if Get_Attribute(Item(NodesList, I), "multiplier") /= "" then
               TempRecord.Multiplier :=
                 Natural'Value
                   (Get_Attribute(Item(NodesList, I), "multiplier"));
            end if;
            LogMessage
              ("Goal added: " & To_String(TempRecord.Index),
               Everything);
            Goals_List.Append(New_Item => TempRecord);
            TempRecord :=
              (Index => Null_Unbounded_String,
               GType => RANDOM,
               Amount => 0,
               TargetIndex => Null_Unbounded_String,
               Multiplier => 1);
         end loop;
      end loop;
      End_Search(Files);
   end LoadGoals;

   function GoalText(Index: Natural) return String is
      Text: Unbounded_String;
      ItemIndex: Positive;
      Goal: Goal_Data;
      InsertPosition: Positive;
      Added: Boolean := False;
      function GetFactionName
        (FactionIndex: Unbounded_String;
         FType: String) return String is
      begin
         for Faction of Factions_List loop
            if To_Lower(To_String(Faction.Index)) =
              To_Lower(To_String(FactionIndex)) then
               if FType = "name" then
                  return To_String(Faction.Name);
               elsif FType = "membername" then
                  return To_String(Faction.MemberName);
               elsif FType = "pluralmembername" then
                  return To_String(Faction.PluralMemberName);
               end if;
               exit;
            end if;
         end loop;
         return "Error";
      end GetFactionName;
   begin
      if Index > 0 then
         Goal := Goals_List(Index);
      else
         Goal := CurrentGoal;
      end if;
      case Goal.GType is
         when REPUTATION =>
            Text := To_Unbounded_String("Gain max reputation in");
         when DESTROY =>
            Text := To_Unbounded_String("Destroy");
         when DISCOVER =>
            Text := To_Unbounded_String("Discover");
         when VISIT =>
            Text := To_Unbounded_String("Visit");
         when CRAFT =>
            Text := To_Unbounded_String("Craft");
         when MISSION =>
            Text := To_Unbounded_String("Finish");
         when KILL =>
            Text := To_Unbounded_String("Kill");
         when RANDOM =>
            null;
      end case;
      Append(Text, Positive'Image(Goal.Amount));
      case Goal.GType is
         when REPUTATION | VISIT =>
            Append(Text, " base");
         when DESTROY =>
            Append(Text, " ship");
         when DISCOVER =>
            Append(Text, " field");
         when CRAFT =>
            Append(Text, " item");
         when MISSION =>
            Append(Text, " mission");
         when KILL =>
            Append(Text, " enem");
         when RANDOM =>
            null;
      end case;
      if (Goal.GType /= RANDOM and Goal.GType /= KILL) and Goal.Amount > 1 then
         Append(Text, "s");
      end if;
      case Goal.GType is
         when DISCOVER =>
            Append(Text, " of map");
         when KILL =>
            if Goal.Amount > 1 then
               Append(Text, "ies in melee combat");
            else
               Append(Text, "y in melee combat");
            end if;
         when others =>
            null;
      end case;
      if Goal.TargetIndex /= Null_Unbounded_String then
         case Goal.GType is
            when REPUTATION | VISIT =>
               InsertPosition := Length(Text) - 3;
               if Goal.Amount > 1 then
                  InsertPosition := InsertPosition - 1;
               end if;
               Insert
                 (Text,
                  InsertPosition,
                  GetFactionName(Goal.TargetIndex, "name") & " ");
            when DESTROY =>
               for I in ProtoShips_List.Iterate loop
                  if ProtoShips_List(I).Index = Goal.TargetIndex then
                     Append(Text, ": " & To_String(ProtoShips_List(I).Name));
                     Added := True;
                     exit;
                  end if;
               end loop;
               if not Added then
                  InsertPosition := Length(Text) - 3;
                  if Goal.Amount > 1 then
                     InsertPosition := InsertPosition - 1;
                  end if;
                  Insert
                    (Text,
                     InsertPosition,
                     To_String(Goal.TargetIndex) & " ");
               end if;
            when CRAFT =>
               if FindRecipe(Goal.TargetIndex) > 0 then
                  ItemIndex :=
                    Recipes_List(FindRecipe(Goal.TargetIndex)).ResultIndex;
                  Append(Text, ": " & To_String(Items_List(ItemIndex).Name));
               else
                  Append(Text, ": " & To_String(Goal.TargetIndex));
               end if;
            when MISSION =>
               case Missions_Types'Value(To_String(Goal.TargetIndex)) is
                  when Deliver =>
                     Append(Text, ": Deliver item to base");
                  when Patrol =>
                     Append(Text, ": Patrol area");
                  when Destroy =>
                     Append(Text, ": Destroy ship");
                  when Explore =>
                     Append(Text, ": Explore area");
                  when Passenger =>
                     Append(Text, ": Transport passenger to base");
               end case;
            when KILL =>
               InsertPosition := Length(Text) - 20;
               if Goal.Amount > 1 then
                  InsertPosition := InsertPosition - 2;
               end if;
               declare
                  StopPosition: Natural := InsertPosition + 4;
               begin
                  if Goal.Amount > 1 then
                     StopPosition := StopPosition + 2;
                     Replace_Slice
                       (Text,
                        InsertPosition,
                        StopPosition,
                        GetFactionName(Goal.TargetIndex, "pluralmembername"));
                  else
                     Replace_Slice
                       (Text,
                        InsertPosition,
                        StopPosition,
                        GetFactionName(Goal.TargetIndex, "membername"));
                  end if;
               end;
            when RANDOM | DISCOVER =>
               null;
         end case;
      end if;
      return To_String(Text);
   end GoalText;

   procedure ClearCurrentGoal is
   begin
      CurrentGoal :=
        (Index => Null_Unbounded_String,
         GType => RANDOM,
         Amount => 0,
         TargetIndex => Null_Unbounded_String,
         Multiplier => 1);
   end ClearCurrentGoal;

   procedure UpdateGoal
     (GType: GoalTypes;
      TargetIndex: Unbounded_String;
      Amount: Positive := 1) is
   begin
      if GType /= CurrentGoal.GType then
         return;
      end if;
      if To_Lower(To_String(TargetIndex)) /=
        To_Lower(To_String(CurrentGoal.TargetIndex)) and
        CurrentGoal.TargetIndex /= Null_Unbounded_String then
         return;
      end if;
      if Amount >= CurrentGoal.Amount then
         CurrentGoal.Amount := 0;
      else
         CurrentGoal.Amount := CurrentGoal.Amount - Amount;
      end if;
      if CurrentGoal.Amount = 0 then
         UpdateFinishedGoals(CurrentGoal.Index);
         AddMessage
           ("You finished your goal. New goal is set.",
            OtherMessage,
            4);
         CurrentGoal :=
           Goals_List
             (GetRandom(Goals_List.First_Index, Goals_List.Last_Index));
      end if;
   end UpdateGoal;

end Goals;
