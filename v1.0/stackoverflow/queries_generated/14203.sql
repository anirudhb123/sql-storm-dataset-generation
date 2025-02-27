-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the average reputation of users who own posts along with the 
-- total count of posts and total score of those posts by post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2022-01-01'  -- Example date filter
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
