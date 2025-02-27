
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
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
    GROUP BY 
        pt.Id, pt.Name
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
