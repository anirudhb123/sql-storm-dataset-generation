
SELECT 
    u.DisplayName, 
    p.Title, 
    p.ViewCount, 
    p.CreationDate 
FROM 
    Posts AS p 
JOIN 
    Users AS u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.ViewCount, 
    p.CreationDate 
ORDER BY 
    p.ViewCount DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
