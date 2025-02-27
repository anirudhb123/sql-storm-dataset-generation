-- Performance Benchmarking Query

-- This query retrieves a list of posts along with their votes and related user information
-- It also calculates the average score of posts and total comments per post for analysis

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS TotalComments,
    AVG(v.VoteTypeId) AS AverageVoteType,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created this year
GROUP BY 
    p.Id, u.Reputation, u.DisplayName
ORDER BY 
    p.ViewCount DESC; -- Order by the most viewed posts
