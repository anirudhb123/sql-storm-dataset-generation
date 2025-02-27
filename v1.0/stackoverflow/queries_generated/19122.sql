SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    p.Score, 
    p.ViewCount, 
   _tags = STRING_AGG(t.TagName, ', ') 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
WHERE 
    p.PostTypeId = 1 -- Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
