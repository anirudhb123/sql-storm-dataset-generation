-- Performance Benchmarking Query

-- This query retrieves the total number of posts, average score, and 
-- average view count for each post type, as well as the number of users 
-- who have created posts in each category.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore, 
    AVG(p.ViewCount) AS AverageViewCount, 
    COUNT(DISTINCT p.OwnerUserId) AS TotalUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
