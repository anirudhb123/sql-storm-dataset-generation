
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
OUTER APPLY 
    STRING_SPLIT(p.Tags, ',') tag
LEFT JOIN 
    Tags t ON t.TagName = tag.value
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
