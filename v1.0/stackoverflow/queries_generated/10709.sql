-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(ph.Id) AS PostHistoryCount,
    SUM(v.BountyAmount) AS TotalBountyAmount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart only
WHERE 
    p.CreationDate >= '2022-01-01' -- Filter for posts created in 2022 or later
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
ORDER BY 
    p.Score DESC, p.ViewCount DESC; -- Order by Score and then ViewCount
