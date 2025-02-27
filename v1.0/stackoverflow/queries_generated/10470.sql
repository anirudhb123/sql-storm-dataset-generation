-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the number of posts by type, the average score of posts, 
-- the total number of votes, and the number of users who have participated,
-- grouped by post type and ordered to identify performance characteristics.

SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS VoteCount FROM Votes GROUP BY PostId) v ON v.PostId = p.Id
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
