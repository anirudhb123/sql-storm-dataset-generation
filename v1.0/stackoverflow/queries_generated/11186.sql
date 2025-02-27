-- Performance Benchmarking SQL Query

-- This query retrieves the number of posts, average score, and average view count
-- across different post types, along with a count of users who contributed to these posts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueContributors
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id   
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
