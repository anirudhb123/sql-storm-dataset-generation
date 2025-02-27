-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the count of posts by type, number of votes per post, 
-- total number of comments, and user reputation aggregated in order to assess
-- performance across different aspects of the system.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
    SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
