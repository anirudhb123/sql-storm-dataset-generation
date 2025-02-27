
SELECT 
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.ViewCount,
    p.CreationDate,
    p.Score,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Tags t ON t.ExcerptPostId = p.Id
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Title,
    u.DisplayName,
    p.ViewCount,
    p.CreationDate,
    p.Score,
    t.TagName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
