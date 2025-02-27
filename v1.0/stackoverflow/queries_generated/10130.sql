-- Performance benchmarking query to analyze the distribution of posts by type and their associated statistics

WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgTimeToActivity, -- in seconds
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    AvgScore,
    TotalViews,
    AvgTimeToActivity,
    UniqueAuthors
FROM 
    PostStats
ORDER BY 
    TotalPosts DESC;
