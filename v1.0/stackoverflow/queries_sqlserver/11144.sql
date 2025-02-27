
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
    p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
GROUP BY 
    p.Id,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.Id,
    u.DisplayName,
    u.Reputation,
    b.Id,
    b.Name,
    b.Class,
    b.Date
ORDER BY 
    p.CreationDate DESC,  
    u.Reputation DESC;
