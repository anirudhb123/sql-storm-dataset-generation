
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
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
    p.Id, p.Title, p.Score, u.DisplayName, p.CreationDate, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
