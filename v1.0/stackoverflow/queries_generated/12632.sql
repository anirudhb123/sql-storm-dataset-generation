-- Benchmarking query to measure performance on the StackOverflow Schema

-- This query retrieves the count of posts, average score, and total views per post type,
-- sorted by post type, which helps understand post distribution and engagement.

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
)
SELECT 
    pt.Name AS PostTypeName,
    ps.TotalPosts,
    ps.AverageScore,
    ps.TotalViews
FROM 
    PostTypes pt
JOIN 
    PostStats ps ON pt.Id = ps.PostTypeId
ORDER BY 
    pt.Id;
