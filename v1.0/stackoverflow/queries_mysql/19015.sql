
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
LIMIT 10;
