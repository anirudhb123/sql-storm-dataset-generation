
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01 12:34:56') AS DATETIME)  
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.AvgScore
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
ORDER BY 
    ps.TotalPosts DESC;
