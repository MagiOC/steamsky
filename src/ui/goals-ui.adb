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

with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with Gtk.Widget; use Gtk.Widget;
with Gtk.Tree_Model; use Gtk.Tree_Model;
with Gtk.Tree_Store; use Gtk.Tree_Store;
with Gtk.Tree_View; use Gtk.Tree_View;
with Gtk.Tree_Selection; use Gtk.Tree_Selection;
with Gtk.Button; use Gtk.Button;
with Glib; use Glib;
with Glib.Error; use Glib.Error;
with Glib.Object; use Glib.Object;
with Game; use Game;
with Goals; use Goals;

package body Goals.UI is

   function HideGoals
     (User_Data: access Gtkada_Builder_Record'Class) return Boolean is
   begin
      return Hide_On_Delete(Gtk_Widget(Get_Object(User_Data, "goalswindow")));
   end HideGoals;

   procedure ShowGoalsMenu(Object: access Gtkada_Builder_Record'Class) is
   begin
      Show_All(Gtk_Widget(Get_Object(Object, "goalswindow")));
   end ShowGoalsMenu;

   procedure GoalSelected(Object: access Gtkada_Builder_Record'Class) is
      Iter: Gtk_Tree_Iter;
      GoalsView: constant Gtk_Tree_View :=
        Gtk_Tree_View(Get_Object(Object, "treegoals"));
      GoalsModel: Gtk_Tree_Model;
   begin
      Get_Selected(Get_Selection(GoalsView), GoalsModel, Iter);
      if Get_String(GoalsModel, Iter, 0) /= "Random" and
        Get_Int(GoalsModel, Iter, 1) = 0 then
         Set_Sensitive(Gtk_Widget(Get_Object(Object, "btnselectgoal")), False);
      else
         Set_Sensitive(Gtk_Widget(Get_Object(Object, "btnselectgoal")), True);
      end if;
   end GoalSelected;

   procedure SelectGoal(Object: access Gtkada_Builder_Record'Class) is
      Iter: Gtk_Tree_Iter;
      GoalsView: constant Gtk_Tree_View :=
        Gtk_Tree_View(Get_Object(Object, "treegoals"));
      GoalsModel: Gtk_Tree_Model;
   begin
      Get_Selected(Get_Selection(GoalsView), GoalsModel, Iter);
      if Get_String(GoalsModel, Iter, 0) = "Random" then
         ClearCurrentGoal;
         Set_Label(Gtk_Button(Get_Object(Object, "btngoal")), "Random");
      else
         CurrentGoal := Goals_List(Positive(Get_Int(GoalsModel, Iter, 1)));
         Set_Label(Gtk_Button(Get_Object(Object, "btngoal")), GoalText(0));
      end if;
      Hide(Gtk_Widget(Get_Object(Object, "goalswindow")));
   end SelectGoal;

   procedure CreateGoalsMenu(Builder: Gtkada_Builder) is
      Error: aliased GError;
      GoalsList: Gtk_Tree_Store;
      CategoryIter: Gtk_Tree_Iter;
      procedure AddGoals(CategoryName: String; GType: GoalTypes) is
         GoalsIter: Gtk_Tree_Iter;
      begin
         Append(GoalsList, CategoryIter, Null_Iter);
         Set(GoalsList, CategoryIter, 0, CategoryName);
         Set(GoalsList, CategoryIter, 1, 0);
         for I in Goals_List.Iterate loop
            if Goals_List(I).GType = GType then
               Append(GoalsList, GoalsIter, CategoryIter);
               Set
                 (GoalsList,
                  GoalsIter,
                  0,
                  GoalText(Goals_Container.To_Index(I)));
               Set(GoalsList, GoalsIter, 1, Gint(Goals_Container.To_Index(I)));
            end if;
         end loop;
      end AddGoals;
   begin
      if Add_From_File
          (Builder,
           To_String(DataDirectory) & "ui" & Dir_Separator & "goals.glade",
           Error'Access) =
        Guint(0) then
         Put_Line("Error : " & Get_Message(Error));
         return;
      end if;
      Register_Handler(Builder, "Show_Goals", ShowGoalsMenu'Access);
      Register_Handler(Builder, "Hide_Goals", HideGoals'Access);
      Register_Handler(Builder, "Goal_Selected", GoalSelected'Access);
      Register_Handler(Builder, "Select_Goal", SelectGoal'Access);
      LoadGoals;
      GoalsList := Gtk_Tree_Store(Get_Object(Builder, "goalslist"));
      Append(GoalsList, CategoryIter, Null_Iter);
      Set(GoalsList, CategoryIter, 0, "Random");
      Set(GoalsList, CategoryIter, 1, 0);
      AddGoals("Gain max reputation in bases", REPUTATION);
      AddGoals("Destroy enemy ships", DESTROY);
      AddGoals("Discover map", DISCOVER);
      AddGoals("Visit bases", VISIT);
      AddGoals("Craft items", CRAFT);
      AddGoals("Finish missions", MISSION);
   end CreateGoalsMenu;

end Goals.UI;
