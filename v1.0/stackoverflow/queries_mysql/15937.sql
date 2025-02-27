
SELECT 
    u.DisplayName AS UserName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
