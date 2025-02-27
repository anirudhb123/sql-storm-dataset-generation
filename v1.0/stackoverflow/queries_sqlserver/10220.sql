
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
    ISNULL(AverageScore, 0) AS AverageScore,
    ISNULL(AverageViewCount, 0) AS AverageViewCount
FROM 
    PostStatistics
ORDER BY 
    PostCount DESC;
