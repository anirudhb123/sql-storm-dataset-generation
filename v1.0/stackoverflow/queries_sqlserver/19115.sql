
SELECT 
    u.DisplayName AS UserName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostDate, 
    p.Score AS PostScore 
FROM 
    Users u 
JOIN 
    Posts p ON u.Id = p.OwnerUserId 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.Score 
ORDER BY 
    p.Score DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
