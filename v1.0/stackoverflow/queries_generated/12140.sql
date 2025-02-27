-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the number of posts, average score, and total views per post type,
-- along with the number of users who have participated in discussions.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- This will help in benchmarking the performance across different post types
-- and understanding the engagement in terms of views and user participation.
