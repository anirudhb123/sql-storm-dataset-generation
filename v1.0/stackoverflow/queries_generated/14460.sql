-- Performance Benchmarking Query

-- This query benchmarks the time taken to retrieve counts of post types and their average views and scores

WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    ps.PostTypeName, 
    ps.PostCount, 
    ps.AvgViewCount, 
    ps.AvgScore,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts  -- Total number of posts for contextual analysis
FROM 
    PostStats ps
ORDER BY 
    ps.PostCount DESC; -- Order by post count for better visibility in results
