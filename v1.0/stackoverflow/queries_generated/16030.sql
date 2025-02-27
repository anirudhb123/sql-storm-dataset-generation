SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    u.DisplayName AS OwnerName, 
    u.Reputation 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 -- Filtering for Questions
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
