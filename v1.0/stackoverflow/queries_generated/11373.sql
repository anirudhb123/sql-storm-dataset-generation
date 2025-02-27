-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS BadgeCount,
    pt.Name AS PostType,
    COALESCE(ph.CreationDate, (SELECT MAX(ph2.CreationDate) FROM PostHistory ph2 WHERE ph2.PostId = p.Id)) AS LastEditedDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the result for performance benchmarking purposes
