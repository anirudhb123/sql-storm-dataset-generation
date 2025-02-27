
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
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount 
ORDER BY 
    p.ViewCount DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
