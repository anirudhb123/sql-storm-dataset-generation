
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    u.CreationDate AS UserCreationDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    MAX(b.Date) AS LastBadgeDate
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
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate
ORDER BY 
    p.CreationDate DESC;
