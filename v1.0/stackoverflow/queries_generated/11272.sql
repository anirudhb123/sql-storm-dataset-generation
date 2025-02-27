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
    COUNT(DISTINCT ph.UserId) AS EditCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Last 30 days
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the results
