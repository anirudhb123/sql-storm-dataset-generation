-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the number of posts, average score, and average view count
-- grouped by post type and order the results for benchmarking performance.

WITH PostPerformance AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    AverageScore,
    AverageViewCount
FROM 
    PostPerformance
ORDER BY 
    TotalPosts DESC; -- Order by the total number of posts descending
