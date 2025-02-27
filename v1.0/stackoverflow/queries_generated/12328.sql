-- Performance benchmarking query to analyze the distribution of posts by type 
-- and the engagement metrics (like views and scores) on those posts.

WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2023-01-01' -- Filtering posts created in 2023
    GROUP BY 
        pt.Name
)

SELECT 
    *,
    ROUND(TotalViews::numeric / NULLIF(TotalPosts, 0), 2) AS ViewsPerPost,
    ROUND(TotalScore::numeric / NULLIF(TotalPosts, 0), 2) AS ScorePerPost
FROM 
    PostMetrics
ORDER BY 
    TotalPosts DESC;
