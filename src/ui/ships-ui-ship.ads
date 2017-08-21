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

package Ships.UI.Ship is

   procedure ShowShipInfo; -- Show informations about ship status

private

   OptionsMenu: Menu;
   MenuWindow, MenuWindow2: Window;
   CurrentMenuIndex: Positive := 1;
   procedure ShowModuleInfo; -- Show info about selected module
   procedure ShowModuleOptions; -- Show options for selected module
   procedure ShowAssignMenu; -- Show assign owner menu for selected module
   function ShowAssignAmmoMenu
     return GameStates; -- Show assign ammo menu for selected gun

end Ships.UI.Ship;