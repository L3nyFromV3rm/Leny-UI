-- This kinda messy, clean up/fix later lol

local ColorPicker = {}
ColorPicker.__index = ColorPicker

local UserInputService = game:GetService("UserInputService")

function ColorPicker.new(context: table)
	local self = setmetatable(context, ColorPicker)
	self.sliderDragging = false
	self.hsvDragging = false
	-- validate keys later
	return self
end

function ColorPicker:updateAssetsColors()
	self.HSV.BackgroundColor3 = Color3.fromHSV(self.H, 1, 1)	
	self.Submit.Background.BackgroundColor3 = Color3.fromHSV(self.H, self.S, self.V)
	self.Hex.Text = Color3.fromHSV(self.H, self.S, self.V):ToHex()
	self.RGB.Text = string.format("%d, %d, %d", self.Submit.Background.BackgroundColor3.R * 255, self.Submit.Background.BackgroundColor3.G * 255, self.Submit.Background.BackgroundColor3.B * 255)
end

function ColorPicker:updateDragPositions()
	self.Slider.Drag.Position = UDim2.new(self.H, 0, 0.5, 0)
	self.HSV.Drag.Position = UDim2.new(self.S, 0, 1 - self.V, 0)
end

function ColorPicker:handleColorPicker(connections)
	-- Set default color
	self:updateColor({color = self.color})

	local inputBegan = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if self.sliderDragging then
				local percentX = (input.Position.X - self.Slider.AbsolutePosition.X) / self.Slider.AbsoluteSize.X

				if percentX >= 0 and percentX <= 1 then
					self.H = math.clamp(percentX, 0, 1)

					self.Slider.Drag.Position = UDim2.new(math.clamp(percentX, 0, 1), 0, 0.5, 0)
					self:updateAssetsColors()
				end
			end

			if self.hsvDragging then
				local percentX = (input.Position.X - self.HSV.AbsolutePosition.X) / self.HSV.AbsoluteSize.X
				local percentY = (input.Position.Y - self.HSV.AbsolutePosition.Y) / self.HSV.AbsoluteSize.Y

				if percentX >= 0 and percentX <= 1 and percentY >= 0 and percentY <= 1 then
					self.S = math.clamp(percentX, 0, 1)
					self.V = 1 - math.clamp(percentY, 0, 1)

					self:updateAssetsColors()
					self:updateDragPositions()
				end
			end
		end
	end)

	table.insert(self.Connections, inputBegan)

	self.Slider.TextButton.MouseButton1Down:Connect(function()
		self.sliderDragging = true

		local touchMoved = UserInputService.TouchMoved:Connect(function(input)
			local percentX = math.clamp((input.Position.X - self.Slider.AbsolutePosition.X) / self.Slider.AbsoluteSize.X, 0, 1)
			self.H = percentX

			self.Slider.Drag.Position = UDim2.new(percentX, 0, 0.5, 0)
			self:updateAssetsColors()
		end) 

		local touchEnded; touchEnded = UserInputService.TouchEnded:Connect(function(input)
			touchMoved:Disconnect()
			touchEnded:Disconnect()
		end)

		local inputChanged = UserInputService.InputChanged:Connect(function(input)
			if self.sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local percentX = math.clamp((input.Position.X - self.Slider.AbsolutePosition.X) / self.Slider.AbsoluteSize.X, 0, 1)
				self.H = percentX

				self.Slider.Drag.Position = UDim2.new(percentX, 0, 0.5, 0)
				self:updateAssetsColors()
			end
		end)

		local inputEnded; inputEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				inputChanged:Disconnect()
				inputEnded:Disconnect()
				self.sliderDragging = false
			end
		end)

		table.insert(self.Connections, touchMoved)
		table.insert(self.Connections, touchEnded)
		table.insert(self.Connections, inputChanged)
		table.insert(self.Connections, inputEnded)
	end)

	self.HSV.TextButton.MouseButton1Down:Connect(function()
		self.hsvDragging = true

		local touchMoved = UserInputService.TouchMoved:Connect(function(input)
			local percentX = math.clamp((input.Position.X - self.Slider.AbsolutePosition.X) / self.Slider.AbsoluteSize.X, 0, 1)
			self.H = percentX

			self.Slider.Drag.Position = UDim2.new(percentX, 0, 0.5, 0)
			self:updateAssetsColors()
		end) 

		local touchEnded; touchEnded = UserInputService.TouchEnded:Connect(function(input)
			touchMoved:Disconnect()
			touchEnded:Disconnect()
		end)

		local inputChanged = UserInputService.InputChanged:Connect(function(input)
			if self.hsvDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local percentX = math.clamp((input.Position.X - self.HSV.AbsolutePosition.X) / self.HSV.AbsoluteSize.X, 0, 1)
				local percentY = math.clamp((input.Position.Y - self.HSV.AbsolutePosition.Y) / self.HSV.AbsoluteSize.Y, 0, 1)
				self.S =percentX
				self.V = 1 - percentY

				self:updateAssetsColors()
				self:updateDragPositions()
			end
		end)

		local inputEnded; inputEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				inputChanged:Disconnect()
				inputEnded:Disconnect()
				self.hsvDragging = false
			end
		end)

		table.insert(self.Connections, touchMoved)
		table.insert(self.Connections, touchEnded)
		table.insert(self.Connections, inputChanged)
		table.insert(self.Connections, inputEnded)
	end)

	self.Hex.FocusLost:Connect(function()		
		if string.match(self.Hex.Text, "^%x%x%x%x%x%x$") then
			self.H, self.S, self.V = Color3.fromHex(self.Hex.Text):ToHSV()
		end

		self:updateAssetsColors()
		self:updateDragPositions()
	end)

	self.RGB.FocusLost:Connect(function()
		if string.match(self.RGB.Text, "^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$") then
			local r, g, b = string.match(self.RGB.Text, "^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
			r, g, b = math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)
			self.H, self.S, self.V = Color3.fromRGB(r, g, b):ToHSV()
		end

		self:updateAssetsColors()
		self:updateDragPositions()
	end)

	self.Submit.TextLabel.TextButton.MouseButton1Down:Connect(function()
		self.Background.BackgroundColor3 = Color3.fromHSV(self.H, self.S, self.V)
		self.color = self.Background.BackgroundColor3
		self.callback(self.Background.BackgroundColor3)
	end)
end

function ColorPicker:updateColor(options: table)
	self.color = options.color or Color3.fromRGB(255, 255, 255)
	self.H, self.S, self.V = options.color:ToHSV()
	self:updateAssetsColors()
	self:updateDragPositions()
	self.Background.BackgroundColor3 = self.color
	self.callback(self.color)
end

return ColorPicker
