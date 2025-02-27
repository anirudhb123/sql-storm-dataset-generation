
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.Score, u.DisplayName, p.CreationDate, p.LastActivityDate
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
