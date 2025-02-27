-- Performance Benchmarking Query: Retrieve detailed information about posts, users, and associated votes

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    v.VoteTypeId,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.Id, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to 100 most recent posts for benchmarking
