-- Performance Benchmarking Query
-- This query retrieves the number of posts, average score, and average view count 
-- grouped by PostType while also joining with the Users table to get user reputation.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- considering posts from the last 1 year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
