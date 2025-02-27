
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(b.Class), 0) AS TotalBadgeClass, 
    COUNT(DISTINCT ph.UserId) AS EditCount,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
WHERE 
    p.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, CAST('2024-10-01' AS DATE))
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
ORDER BY 
    p.CreationDate DESC;
