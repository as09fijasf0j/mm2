print("--- REMOTE SCAN ---")
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print(obj:GetFullName(), "|", obj.ClassName)
    end
end
print("--- SCAN COMPLETE ---")
