-- Performance benchmarking for posts with their associated user and vote counts
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
    COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
