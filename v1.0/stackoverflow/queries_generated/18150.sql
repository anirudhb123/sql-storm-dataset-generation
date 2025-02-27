SELECT 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount 
FROM 
    Users u 
JOIN 
    Posts p ON u.Id = p.OwnerUserId 
WHERE 
    p.PostTypeId = 1 -- Considering only Questions
ORDER BY 
    p.ViewCount DESC 
LIMIT 10;
