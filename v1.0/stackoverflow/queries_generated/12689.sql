-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    p.Body,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '30 days' -- Filter for recent posts
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC -- Order by score
LIMIT 100; -- Limit to top 100 posts for benchmarking
