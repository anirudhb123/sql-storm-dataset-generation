-- Performance benchmarking query for Stack Overflow schema
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    u.DisplayName AS Owner,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    MAX(ph.CreationDate) AS LastHistoryChange
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC, CommentCount DESC
LIMIT 100; -- Limit the results to the top 100 posts
