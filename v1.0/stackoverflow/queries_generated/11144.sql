-- Performance benchmarking query for posts and associated users and their badges
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    b.Id AS BadgeId,
    b.Name AS BadgeName,
    b.Class AS BadgeClass,
    b.Date AS BadgeDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
ORDER BY 
    p.CreationDate DESC,  -- Order by post creation date
    u.Reputation DESC;  -- Then by user reputation
