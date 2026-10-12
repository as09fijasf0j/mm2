for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Tool") then
        print("Found Tool:", obj:GetFullName())
    end
end
