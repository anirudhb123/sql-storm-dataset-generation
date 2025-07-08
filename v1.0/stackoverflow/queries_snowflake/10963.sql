
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    p.Score,
    p.ViewCount,
    LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL SPLIT_TO_TABLE(p.Tags, ',') AS tag ON TRUE
LEFT JOIN 
    Tags t ON tag.VALUE = t.TagName
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
