
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
ORDER BY 
    p.ViewCount DESC
LIMIT 10;
