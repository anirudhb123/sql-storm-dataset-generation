-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
    COUNT(DISTINCT ph.Id) AS EditHistoryCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
