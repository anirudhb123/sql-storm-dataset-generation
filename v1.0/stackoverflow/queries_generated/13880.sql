-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves statistics regarding posts, including the number of questions,
-- average view counts, and average scores to analyze performance across different post types.

WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostTypeName,
    PostCount,
    AvgViewCount,
    AvgScore
FROM 
    PostStats
ORDER BY 
    PostCount DESC;
