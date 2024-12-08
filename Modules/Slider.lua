local Slider = {}
Slider.__index = Slider

function Slider.new(context: table)
	local self = setmetatable(context, Slider)
	-- Auto size textbox
	self.autoSizeTextBox()
	self.TextBox:GetPropertyChangedSignal("Text"):Connect(self.autoSizeTextBox)
	self.TextBox.FocusLost:Connect(function()
		local number = tonumber(self.TextBox.Text)
		self:updateValue({value = number})
	end)
	
	self.dragging = false
	-- validate keys later
	return self
end

function Slider:handleSlider(connections)
	local UserInputService = game:GetService("UserInputService")
	
	local function round(number: number)
		-- credits to waves5217 for this function
		local function formatChance(chance: number)
			local formatted = string.format("%.3f", chance) --> omit to three decimals
			formatted = formatted:gsub("%.?0+$", "") --> remove the dot and trailing zeroes
			return formatted
		end

		if self.step == 0 then
			return math.floor(number)
		else
			return tonumber(formatChance(math.round(number * 10^self.step) * 10^-self.step))
		end
	end
	
	-- should probably do a check if the line has a textbutton or not, for more universal
	self.Line.TextButton.MouseButton1Down:Connect(function(input)
		self.dragging = true
		
		local touchMoved = UserInputService.TouchMoved:Connect(function(input)
			if self.dragging then
				local min, max = self.min, self.max
				local percent = math.clamp((input.Position.X - self.Line.AbsolutePosition.X) / self.Line.AbsoluteSize.X, 0, 1)
				local value = round((percent * (max - min)) + min)

				self.showInfo()
				self:updateValue({value = value})
			end
		end)		
		
		local touchEnded; touchEnded = UserInputService.TouchEnded:Connect(function(input)
			self.dragging = false
			self.dontShowInfo()
			touchEnded:Disconnect()
			touchMoved:Disconnect()
		end)
		
		local inputChanged = UserInputService.InputChanged:Connect(function(input)
			if self.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local min, max = self.min, self.max
				local percent = math.clamp((input.Position.X - self.Line.AbsolutePosition.X) / self.Line.AbsoluteSize.X, 0, 1)
				local value = round((percent * (max - min)) + min)

				self.showInfo()
				self:updateValue({value = value})
			end
		end)		

		local inputEnded; inputEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self.dragging = false
				self.dontShowInfo()
				inputEnded:Disconnect()
				inputChanged:Disconnect()
			end
		end)
		
		table.insert(self.Connections, touchMoved)
		table.insert(self.Connections, touchEnded)
		table.insert(self.Connections, inputChanged)
		table.insert(self.Connections, inputEnded)
	end)
	
	self:updateValue({value = self.value})
end

function Slider:updateValue(options: table)
	local newValue = options.value or self.min
	
	if typeof(newValue) ~= "number" then
		newValue = self.min
	end
	
	if newValue > self.max or newValue < self.min then
		warn("Value out of range, putting newValue to min value")
		newValue = self.min
	end
	
	local percent = (math.clamp(newValue, self.min, self.max) - self.min) / (self.max - self.min)
	
	self.updateFill(percent)
	self.value = newValue
	self.callback(newValue)
	self.CurrentValueLabel.Text = newValue
	self.TextBox.Text = newValue
end

return Slider
