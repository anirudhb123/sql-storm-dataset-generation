-- Performance Benchmarking SQL Query

-- This query evaluates the number of posts created by users 
-- along with the average view count and score for each post type.

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.AverageViews,
    ps.AverageScore
FROM 
    PostTypes pt
JOIN 
    PostStats ps ON pt.Id = ps.PostTypeId
ORDER BY 
    ps.TotalPosts DESC;
