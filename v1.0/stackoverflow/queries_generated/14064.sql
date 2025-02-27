-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.Score) AS TotalVotes,
    COALESCE(ph.RevisionCount, 0) AS PostRevisionCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         PostId,
         COUNT(*) AS RevisionCount 
     FROM 
         PostHistory 
     GROUP BY 
         PostId) ph ON p.Id = ph.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Consider posts from 2023 onwards
GROUP BY 
    p.Id, 
    u.DisplayName, 
    ph.RevisionCount
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 100; -- Limit to top 100 posts for benchmarking
