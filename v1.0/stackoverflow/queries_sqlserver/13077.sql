
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.Score,
    p.CreationDate
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    u.Reputation > 0 
GROUP BY 
    u.Id, 
    u.DisplayName, 
    u.Reputation, 
    p.Title, 
    p.Score, 
    p.CreationDate
ORDER BY 
    u.Reputation DESC, 
    p.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
