-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.DisplayName, t.TagName
ORDER BY 
    p.ViewCount DESC
LIMIT 100;
