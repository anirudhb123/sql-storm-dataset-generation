-- Performance benchmarking: Count of active posts by type and average score of those posts
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS ActivePostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Posts created in the last year
    GROUP BY 
        pt.Name
)
SELECT 
    PostType,
    ActivePostCount,
    AvgScore
FROM 
    PostStats
ORDER BY 
    ActivePostCount DESC;
