-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    p.AnswerCount,
    pt.Name AS PostType,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) AS EditCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tagsArray ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tagsArray 
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    p.Id, u.DisplayName, pt.Name
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
