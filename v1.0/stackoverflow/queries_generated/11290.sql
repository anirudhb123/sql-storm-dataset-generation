-- Performance Benchmarking: Analyzing Posts Metrics over Last 12 Months

WITH PostMetrics AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT p.OwnerUserId) AS TotalAuthors,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AverageViews,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY 
        p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    pm.TotalPosts,
    pm.TotalAuthors,
    pm.TotalScore,
    pm.AverageScore,
    pm.TotalViews,
    pm.AverageViews,
    pm.TotalComments
FROM 
    PostMetrics pm
JOIN 
    PostTypes pt ON pm.PostTypeId = pt.Id
ORDER BY 
    pm.TotalPosts DESC;
