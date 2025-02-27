
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.Id AS UserId,
    u.Reputation,
    u.DisplayName AS UserDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(b.Id) AS BadgeCount
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
    p.CreationDate > NOW() - INTERVAL 1 YEAR
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Id, u.Reputation, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
