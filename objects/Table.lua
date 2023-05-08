return function(name, basalt)
    local base = basalt.getObject("ScrollableFrame")(name, basalt)
    local objectType = "Table"

    local updateLayout = false
    local columnAmount = 3
    local gutterX, gutterY = 1, 1
	local paddingX, paddingY = 0, 0
    local fixedWidths = {}
    local tableObjects = {}

    local function getMaxHeightInRow(objects, startIndex, endIndex)
        local maxHeight = 0
        for i = startIndex, endIndex do
            local obj = objects[i]
            if obj then
                maxHeight = math.max(maxHeight, obj:getHeight())
            end
        end
        return maxHeight
    end
    
    local function applyLayout(self)
        local containerWidth, _ = self:getSize()
        local objects = tableObjects
    
        local remainingWidth = containerWidth - gutterX - paddingX * (columnAmount - 1)
        for _, width in ipairs(fixedWidths) do
            remainingWidth = remainingWidth - width
        end
        local dynamicColumnWidth = remainingWidth / (columnAmount - #fixedWidths)
    
        local rowIndex = 1
        local columnIndex = 1
        local currentX = 1 + paddingX
        local currentY = 1 + paddingY
    
        for i, obj in ipairs(objects) do
            local columnWidth = fixedWidths[rowIndex] or dynamicColumnWidth
    
            obj:setPosition(currentX, currentY)
            obj:setSize(columnWidth, obj:getHeight())
    
            currentX = currentX + columnWidth + gutterX
            rowIndex = rowIndex + 1
    
            if rowIndex > columnAmount then
                local maxHeightInRow = getMaxHeightInRow(objects, i - columnAmount + 1, i)
                rowIndex = 1
                columnIndex = columnIndex + 1
                currentX = 1 + paddingX
                currentY = currentY + maxHeightInRow + gutterY
            end
        end
    end

    local object = {
        getType = function()
            return objectType
        end,

        isType = function(self, t)
            return objectType == t or base.getBase(self).isType(t) or false
        end,

        setColumnAmount = function(self, amount)
            columnAmount = amount
			updateLayout = true
            return self
        end,

        setGutter = function(self, newGutterX, newGutterY)
            gutterX = newGutterX
			gutterY = newGutterY
			updateLayout = true
            return self
        end,

        setColumnWidth = function(self, columnIndex, width)
            fixedWidths[columnIndex] = width
			updateLayout = true
            return self
        end,
		
		setPadding = function(self, newPaddingX, newPaddingY)
			paddingX = newPaddingX
			paddingY = newPaddingY
			updateLayout = true
			return self
		end,
	
    	applyLayout = applyLayout,

        updateLayout = function(self)
            updateLayout = true
            return self
        end,

        draw = function(self)
            base.draw(self)
            self:addDraw("tableDraw", function()
                if(updateLayout)then
                    applyLayout(self)
                    updateLayout = false
                end
            end, 1)
        end,
    }

    for k, _ in pairs(basalt.getObjects()) do
        object["add" .. k] = function(self, name)
            local obj = base["add" .. k](self, name)
            table.insert(tableObjects, obj)
            updateLayout = true
			return obj
        end
    end

    object.__index = object
    return setmetatable(object, base)
end
