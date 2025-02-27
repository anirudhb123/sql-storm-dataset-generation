-- Performance benchmarking query to analyze Posts and Users
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
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
ORDER BY 
    p.ViewCount DESC, p.CreationDate DESC;  -- Order by view count and then by creation date
