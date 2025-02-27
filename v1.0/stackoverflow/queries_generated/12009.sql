-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the count of posts by type, average score, and total views,
-- along with user reputation, to analyze the performance of posts and user engagement.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
