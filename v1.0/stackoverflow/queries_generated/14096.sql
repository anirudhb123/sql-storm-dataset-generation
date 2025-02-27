-- Performance benchmarking query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
    COALESCE(b.Name, 'No Badge') AS UserBadge
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
WHERE 
    p.PostTypeId = 1 -- Considering only Questions
GROUP BY 
    p.Id, u.DisplayName, b.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit for performance testing
