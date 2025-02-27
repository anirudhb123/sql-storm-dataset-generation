-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ','))
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days' -- Filter for posts created in the last 30 days
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
