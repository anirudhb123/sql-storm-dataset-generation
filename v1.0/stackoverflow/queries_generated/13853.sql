-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filter: posts created in 2023
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
ORDER BY 
    p.ViewCount DESC  -- Sort by ViewCount
LIMIT 100;  -- Limit results to top 100 posts
