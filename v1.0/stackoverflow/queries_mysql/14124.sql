
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    p.Score AS PostScore,
    p.ViewCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName, u.Reputation, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
