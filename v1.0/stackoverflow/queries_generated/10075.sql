-- Performance benchmarking SQL query for StackOverflow schema

-- This query fetches the count of posts, average score, and total views 
-- grouped by post type, along with user reputation count
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT u.Id) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01'  -- filter for posts created in the current year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
