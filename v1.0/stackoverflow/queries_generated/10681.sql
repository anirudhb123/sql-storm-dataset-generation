-- Performance Benchmarking SQL Query Example

-- This query retrieves the average score and view count of posts grouped by post type,
-- along with counts of users and tags associated with those posts. It aggregates 
-- data to assess performance by joining relevant tables and applying aggregate functions.

SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS TotalUsers,
    COUNT(DISTINCT t.Id) AS TotalTags
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
GROUP BY 
    pt.Name
ORDER BY 
    !AverageScore DESC;
