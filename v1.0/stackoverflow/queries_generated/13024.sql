-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves a summary of posts along with user reputation and badge count

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2022-01-01' -- Filter for posts created in 2022 and later
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC, p.CreationDate DESC; -- Order by score and creation date
