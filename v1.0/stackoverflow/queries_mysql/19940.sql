
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.CreationDate AS PostDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title, p.Score, p.CreationDate
ORDER BY 
    p.Score DESC
LIMIT 10;
