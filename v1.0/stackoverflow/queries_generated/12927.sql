-- Performance benchmarking for total post counts and average scores by post type

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- considers only posts from the last year
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
