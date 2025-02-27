-- Performance Benchmarking Query
-- This query retrieves the average score and view counts for posts by each post type,
-- along with the total number of posts and users who created them.

WITH PostStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- change interval as needed for benchmarking
    GROUP BY 
        pt.Name
)

SELECT 
    PostTypeName,
    TotalPosts,
    COALESCE(AverageScore, 0) AS AverageScore,
    COALESCE(AverageViewCount, 0) AS AverageViewCount,
    UniqueUsers
FROM 
    PostStats
ORDER BY 
    TotalPosts DESC;
