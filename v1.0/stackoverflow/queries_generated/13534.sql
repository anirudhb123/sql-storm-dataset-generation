-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 1 THEN 1 ELSE 0 END) AS InitialTitlesCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostsCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
