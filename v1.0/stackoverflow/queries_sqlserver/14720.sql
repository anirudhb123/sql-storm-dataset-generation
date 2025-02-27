
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    u.LastAccessDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
GROUP BY 
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate
ORDER BY 
    p.ViewCount DESC, 
    p.CreationDate DESC;
