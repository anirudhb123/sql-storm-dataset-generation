
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
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR  
ORDER BY 
    p.ViewCount DESC, p.CreationDate DESC;
