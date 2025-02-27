-- Performance Benchmarking Query
-- This query retrieves the number of posts, average score, and average view count grouped by post type,
-- while also counting the number of distinct users who created posts for each type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS DistinctUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;
