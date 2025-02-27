-- Performance Benchmarking Query
-- This query retrieves the count of posts, average score, and total votes along with the user reputation 
-- to benchmark the performance of various posts and their engagement.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.PostTypeId,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    AVG(p.Score) AS AverageScore,
    u.Reputation AS UserReputation,
    p.CreationDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- filtering posts created within the last year
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    AverageScore DESC
LIMIT 100;  -- limit to the top 100 posts by average score
