-- Performance Benchmarking Query
-- This query retrieves the count of posts, average score, and average view count grouped by post type
WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    PostCount,
    COALESCE(AverageScore, 0) AS AverageScore,
    COALESCE(AverageViewCount, 0) AS AverageViewCount
FROM 
    PostStatistics
ORDER BY 
    PostCount DESC;
