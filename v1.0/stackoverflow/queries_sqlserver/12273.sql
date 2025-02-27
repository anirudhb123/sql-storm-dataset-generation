
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
OUTER APPLY 
    (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, ',')) AS tag
LEFT JOIN 
    Tags t ON t.TagName = tag.TagName
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId IN (1, 2) 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
