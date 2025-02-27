-- Performance Benchmarking SQL Query

-- Measure the time taken to execute the query that retrieves the total number of posts by type,
-- along with average score and view count for each post type.

WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
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
    TotalPosts,
    AverageScore,
    AverageViewCount
FROM 
    PostStats
ORDER BY 
    TotalPosts DESC;

-- Optionally, to create an index for performance optimization
CREATE INDEX idx_posttypes_posttypeid ON Posts(PostTypeId);
