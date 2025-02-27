-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the average score and view count of posts,
-- along with the user reputation who created the posts,
-- to observe the performance metrics related to post engagement.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    u.Reputation AS UserReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
