-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    pt.Name AS PostType,
    u.DisplayName AS Owner,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,      -- Sum of UpVotes
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,    -- Sum of DownVotes
    COALESCE(SUM(b.Id IS NOT NULL), 0) AS BadgeCount,   -- Count of Badges owned by the user
    COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount -- Count of Close History
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
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
    p.Id, pt.Name, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limiting results for performance considerations
