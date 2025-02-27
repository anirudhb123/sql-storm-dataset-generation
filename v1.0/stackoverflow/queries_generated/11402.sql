-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves a summary of posts, their average score, view count, and associated user reputation.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    AVG(vote.Score) AS AverageVoteScore,
    COUNT(c.Id) AS CommentCount,
    u.Reputation AS UserReputation
FROM 
    Posts p
LEFT JOIN 
    Votes vote ON p.Id = vote.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
