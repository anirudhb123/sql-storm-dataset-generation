
SELECT 
    u.Id AS UserId, 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.Score 
FROM 
    Users u 
JOIN 
    Posts p ON u.Id = p.OwnerUserId 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.Id, u.DisplayName, p.Title, p.CreationDate, p.Score 
ORDER BY 
    p.Score DESC 
LIMIT 10;
