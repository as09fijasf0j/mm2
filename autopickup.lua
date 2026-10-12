-- Diagnostic: List everything in Workspace that looks like a gun
print("--- SCANNING WORKSPACE ---")
for _, obj in ipairs(workspace:GetDescendants()) do
    -- Look for objects with "Gun", "Knife", "Pistol", or "Handle" in their name
    -- This is a broad net to catch what MM2 calls it
    local name = obj.Name:lower()
    if name:find("gun") or name:find("knife") or name:find("pistol") or name:find("handle") then
        print("FOUND:", obj:GetFullName(), "| Class:", obj.ClassName)
    end
end
print("--- SCAN COMPLETE ---")
