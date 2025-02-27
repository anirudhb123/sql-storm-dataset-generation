-- Performance Benchmark Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
    AVG(ph.RevisionGUID) AS AvgRevisionCount
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
    p.CreationDate >= '2023-01-01' -- Filtering for posts created in 2023
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100; -- Limit to top 100 posts by score
