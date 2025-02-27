-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the count of posts by type, average score of posts, and total views,
-- while grouping the results by the post type. 

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;
