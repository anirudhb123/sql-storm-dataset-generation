-- Performance Benchmarking Query

-- This query retrieves the number of posts, average score, and total views from the Posts table,
-- grouping the results by PostType and sorting by the number of posts in descending order.

SELECT 
    pt.Name AS PostTypeName,
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
