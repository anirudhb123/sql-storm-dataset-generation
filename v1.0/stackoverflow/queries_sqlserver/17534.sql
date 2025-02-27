
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
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
    p.Id,
    p.Title,
    u.DisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    t.TagName
ORDER BY 
    p.Score DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
