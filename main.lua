-- 
-- Abstract: List View sample app
--  
-- Version: 2.0
-- 
-- Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- Copyright (C) 2013 Corona Labs Inc. All Rights Reserved.
--
-- Demonstrates how to create a list view using the widget's Table View Library.
-- A list view is a collection of content organized in rows that the user
-- can scroll up or down on touch. Tapping on each row can execute a 
-- custom function.
--
-- Supports Graphics 2.0
------------------------------------------------------------
------------------Text Wrapping Functions -----------------------
-- Wrap text
function wrap(str, limit, indent, indent1)
  indent = indent or ""
  indent1 = indent1 or indent
  limit = limit or 72
  local here = 1-#indent1
  return indent1..str:gsub("(%s+)()(%S+)()",
                          function(sp, st, word, fi)
                            if fi-here > limit then
                              here = st - #indent
                              return "\n"..indent..word
                            end
                          end)
end
 
function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end
 
function wrappedText(str, limit, size, font, color, indent, indent1)
        str = explode("\n", str)
        size = tonumber(size) or 12
        color = color or {255, 255, 255}
        font = font or "Helvetica"      
 
        --apply line breaks using the wrapping function
        local i = 1
        local strFinal = ""
    while i <= #str do
                strW = wrap(str[i], limit, indent, indent1)
                strFinal = strFinal.."\n"..strW
                i = i + 1
        end
        str = strFinal
        
        --search for each line that ends with a line break and add to an array
        local pos, arr = 0, {}
        for st,sp in function() return string.find(str,"\n",pos,true) end do
                table.insert(arr,string.sub(str,pos,st-1)) 
                pos = sp + 1 
        end
        table.insert(arr,string.sub(str,pos)) 
                        
        --iterate through the array and add each item as a display object to the group
        local g = display.newGroup()
        local i = 1
    while i <= #arr do
                local t = display.newText( arr[i], 0, 0, font, size )    
                t:setTextColor( color[1], color[2], color[3] )
                t.x = math.floor(t.width/2)
                t.y = (size*1.3)*(i-1)
                g:insert(t)
                i = i + 1
        end
        return g
end

------------------End Text Wrapping Functions -----------------------
display.setStatusBar( display.HiddenStatusBar ) 
require "sqlite3"
local id=0
local path = system.pathForFile( "data.db", system.DocumentsDirectory )
print("path="..path)
local db = sqlite3.open( path )

local tablesetup = [[CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY autoincrement, level, description, datetime);]]
db:exec( tablesetup )

local insertQuery = [[INSERT INTO logs VALUES (NULL, 'Error','This is an unknown 21.', ']]..os.date()..[['); ]]
db:exec( insertQuery )
print(insertQuery)
--import the widget library
local widget = require( "widget" )

-- create a constant for the left spacing of the row content
local LEFT_PADDING = 10

--Set the background to white
display.setDefault( "background", 1, 1, 1 )

--Create a group to hold our widgets & images
local widgetGroup = display.newGroup()

-- The gradient used by the title bar
local titleGradient = {
	type = 'gradient',
	color1 = { 189/255, 203/255, 220/255, 255/255 }, 
	color2 = { 89/255, 116/255, 152/255, 255/255 },
	direction = "down"
}

-- Create toolbar to go at the top of the screen
local titleBar = display.newRect( display.contentCenterX, 0, display.contentWidth, 32 )
titleBar:setFillColor( titleGradient )
titleBar.y = display.screenOriginY + titleBar.contentHeight * 0.5

-- create embossed text to go on toolbar
local titleText = display.newEmbossedText( "Log List", display.contentCenterX, titleBar.y, native.systemFontBold, 20 )

-- create a shadow underneath the titlebar (for a nice touch)
local shadow = display.newImage( "shadow.png" )
shadow.anchorX = 0; shadow.anchorY = 0		-- TopLeft anchor
shadow.x, shadow.y = 0, titleBar.y + titleBar.contentHeight * 0.5
shadow.xScale = 320 / shadow.contentWidth
shadow.alpha = 0.45

--Text to show which item we selected
local itemSelected = display.newText( "You selected", 0, 0, native.systemFontBold, 24 )
itemSelected:setFillColor( 0 )
itemSelected.x = display.contentWidth + itemSelected.contentWidth * 0.5
itemSelected.y = display.contentCenterY
widgetGroup:insert( itemSelected )

-- Forward reference for our back button & tableview
local delButton, backButton, list
local rowTitles = {}

-- Handle row rendering
local function onRowRender( event )
	local phase = event.phase
	local row = event.row
	local isCategory = row.isCategory
	
	-- in graphics 2.0, the group contentWidth / contentHeight are initially 0, and expand once elements are inserted into the group.
	-- in order to use contentHeight properly, we cache the variable before inserting objects into the group

	local groupContentHeight = row.contentHeight
	
	local rowTitle = display.newText( row, rowTitles[row.index], 0, 0, native.systemFontBold, 16 )

	-- in Graphics 2.0, the row.x is the center of the row, no longer the top left.
	rowTitle.x = LEFT_PADDING

	-- we also set the anchorX of the text to 0, so the object is x-anchored at the left
	rowTitle.anchorX = 0

	rowTitle.y = groupContentHeight * 0.5
	rowTitle:setFillColor( 0, 0, 0 )
	
	if not isCategory then
		local rowArrow = display.newImage( row, "rowArrow.png", false )
		rowArrow.x = row.contentWidth - LEFT_PADDING

		-- we set the image anchorX to 1, so the object is x-anchored at the right
		rowArrow.anchorX = 1

		-- we set the image anchorX to 1, so the object is x-anchored at the right
		rowArrow.y = groupContentHeight * 0.5
	end
end

-- Hande row touch events
local function onRowTouch( event )
	local phase = event.phase
	local row = event.target
	
	if "press" == phase then
		print( "Pressed row: " .. row.index )

	elseif "release" == phase then
		-- Update the item selected text
		local p = string.find(rowTitles[row.index], "---", 1)
		id = string.sub(rowTitles[row.index],1,p-1)
		print("id="..id)
		local desc
		for row in db:nrows("SELECT * FROM logs WHERE id="..id) do
			desc = row.description..row.datetime
		end
		local nObject = wrappedText( desc, 40, 16, "Helvetica", {255, 0, 0} )
		itemSelected.text = nObject
		print(itemSelected.text)
		--Transition out the list, transition in the item selected text and the back button

		-- The table x origin refers to the center of the table in Graphics 2.0, so we translate with half the object's contentWidth
		transition.to( list, { x = - list.contentWidth * 0.5, time = 400, transition = easing.outExpo } )
		transition.to( nObject, { x = display.contentCenterX*0.1, time = 400, transition = easing.outExpo } )
		transition.to( delButton, { alpha = 1, time = 400, transition = easing.outQuad } )
		transition.to( backButton, { alpha = 1, time = 400, transition = easing.outQuad } )
		transition.to( titleText, { alpha = 0, time = 400, transition = easing.outQuad } )
		transition.to( titleBar, { alpha = 0, time = 400, transition = easing.outQuad } )
		
		print( "Tapped and/or Released row: " .. row.index )
	end
end

-- Create a tableView
list = widget.newTableView
{
	top = 32,
	width = 320, 
	height = 448,
	maskFile = "mask-320x448.png",
	onRowRender = onRowRender,
	onRowTouch = onRowTouch,
}

--Insert widgets/images into a group
widgetGroup:insert( list )
widgetGroup:insert( titleBar )
widgetGroup:insert( titleText )
widgetGroup:insert( shadow )



local function BindData()
	local listItems = {}
	for row in db:nrows("SELECT level,count(level) as num  FROM logs group by level") do
		print( "current index" .. #listItems+1)
		--create table at next available array index
		listItems[#listItems+1] =
		{
			title = row.level.."("..row.num..")",
			items = {}
		}
		for rowd in db:nrows("SELECT * FROM logs WHERE level='"..row.level.."'") do
			local desc=rowd.description
			print("desc..."..desc)
			local strlen = 30
			if string.len(desc) > strlen then
				desc = string.sub(desc,1,strlen)
			else
				desc = string.sub(desc,1,string.len(desc))
			end
			table.insert(listItems[#listItems].items,rowd.id.."---"..desc)
		end
	end
	---[[ **Remove This**
	-- insert rows into list (tableView widget)
	for i = 1, #listItems do
		--Add the rows category title
		rowTitles[ #rowTitles + 1 ] = listItems[i].title
		
		--Insert the category
		list:insertRow{
			rowHeight = 24,
			rowColor = 
			{ 
				default = { 150/255, 160/255, 180/255, 200/255 },
			},
			isCategory = true,
		}

		--Insert the item
		for j = 1, #listItems[i].items do
			--Add the rows item title
			rowTitles[ #rowTitles + 1 ] = listItems[i].items[j]
			
			--Insert the item
			list:insertRow{
				rowHeight = 40,
				isCategory = false,
				listener = onRowTouch
			}
		end
	end

	--]]
end

BindData()
--Handle the back button release event
local function onBackRelease()
	--Transition in the list, transition out the item selected text and the back button

	-- The table x origin refers to the center of the table in Graphics 2.0, so we translate with half the object's contentWidth
	transition.to( list, { x = list.contentWidth * 0.5, time = 400, transition = easing.outExpo } )
	transition.to( itemSelected, { x = display.contentWidth + itemSelected.contentWidth * 0.5, time = 400, transition = easing.outExpo } )
	transition.to( backButton, { alpha = 0, time = 400, transition = easing.outQuad } )
	transition.to( delButton, { alpha = 0, time = 400, transition = easing.outQuad } )
	transition.to( titleText, { alpha = 1, time = 400, transition = easing.outQuad } )
	transition.to( titleBar, { alpha = 1, time = 400, transition = easing.outQuad } )
end

--Handle the delete button release event
local function onDelRelease()
	--Transition in the list, transition out the item selected text and the back button
	print("id="..id)
	local deleteQuery = [[DELETE FROM logs WHERE id=]]..id
	db:exec( deleteQuery )
	print(deleteQuery)

	-- The table x origin refers to the center of the table in Graphics 2.0, so we translate with half the object's contentWidth
	transition.to( list, { x = list.contentWidth * 0.5, time = 400, transition = easing.outExpo } )
	transition.to( itemSelected, { x = display.contentWidth + itemSelected.contentWidth * 0.5, time = 400, transition = easing.outExpo } )
	transition.to( delButton, { alpha = 0, time = 400, transition = easing.outQuad } )
	transition.to( backButton, { alpha = 0, time = 400, transition = easing.outQuad } )
	transition.to( titleText, { alpha = 1, time = 400, transition = easing.outQuad } )
	transition.to( titleBar, { alpha = 1, time = 400, transition = easing.outQuad } )
	BindData()
end


--Create the delete button
delButton = widget.newButton
{
	width = 298,
	height = 86,
	label = "Delete", 
	labelYOffset = - 1,
	onRelease = onDelRelease
}
delButton.alpha = 0
delButton.x = display.contentCenterX
delButton.y = display.contentHeight - delButton.contentHeight
widgetGroup:insert( delButton )

--Create the back button
backButton = widget.newButton
{
	width = 298,
	height = 56,
	label = "Back", 
	labelYOffset = - 1,
	onRelease = onBackRelease
}
backButton.alpha = 0
backButton.x = display.contentCenterX
backButton.y = display.contentHeight - backButton.contentHeight
widgetGroup:insert( backButton )


local function onSystemEvent( event )
	if event.type == "applicationExit" then
		if db and db:isopen() then
			print("db close")
			db:close()
		end
	end
end
Runtime:addEventListener( "system", onSystemEvent )
