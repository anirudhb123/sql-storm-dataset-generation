-- Performance Benchmarking Query

-- This query retrieves the count of posts by post type, average scores, and total views.
-- It aggregates data to evaluate the performance by PostTypeId

WITH PostMetrics AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Id, pt.Name
)

SELECT 
    PostTypeId,
    PostTypeName,
    PostCount,
    AverageScore,
    TotalViews
FROM 
    PostMetrics
ORDER BY 
    PostCount DESC;
