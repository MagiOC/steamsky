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

with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Terminal_Interface.Curses.Forms; use Terminal_Interface.Curses.Forms;
with Game; use Game;

package Trades.UI is

   procedure ShowTrade; -- Show trade window

private
   Buy: Boolean; -- If true, buy item, otherwise sell it
   TradeForm: Form; -- Form for set item amount for trade
   FormWindow: Window; -- Window for tradinf form

   procedure ShowItemInfo; -- Show detailed informations about selected item
   function ShowTradeForm
     return GameStates; -- Show trade form for buy/sell item

end Trades.UI;