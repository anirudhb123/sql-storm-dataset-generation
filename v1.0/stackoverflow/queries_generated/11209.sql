-- Performance benchmarking query to analyze various aspects of the StackOverflow schema

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id) AS VoteCount,
    (SELECT COUNT(*) FROM Badges WHERE UserId = p.OwnerUserId) AS OwnerBadgeCount,
    u.Reputation AS OwnerReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
ORDER BY 
    p.ViewCount DESC, p.Score DESC
LIMIT 100;  -- Limit the results to the top 100 posts
