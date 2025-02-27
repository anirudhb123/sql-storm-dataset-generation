-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the count of Posts, the average Score, 
-- and the maximum ViewCount grouped by PostTypeId, also joining necessary tables.

WITH PostMetrics AS (
    SELECT 
        pt.Id AS PostTypeId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        MAX(p.ViewCount) AS MaxViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- focusing on the last year
    GROUP BY 
        pt.Id
)

SELECT 
    pt.Name AS PostTypeName,
    pm.PostCount,
    pm.AverageScore,
    pm.MaxViewCount
FROM 
    PostMetrics pm
JOIN 
    PostTypes pt ON pm.PostTypeId = pt.Id
ORDER BY 
    pm.PostCount DESC;
