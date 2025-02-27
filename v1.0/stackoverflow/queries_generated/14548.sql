-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the count of posts, average score, and total view count per post type
WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

-- Summarize the results for performance comparison
SELECT 
    PostType, 
    PostCount, 
    AvgScore, 
    TotalViewCount
FROM 
    PostMetrics
ORDER BY 
    PostCount DESC;
