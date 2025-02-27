
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName, 
    u.Reputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    u.DisplayName, 
    u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
