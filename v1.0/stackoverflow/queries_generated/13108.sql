-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the total number of posts, the average score of posts,
-- and the average view count of posts grouped by PostTypeId.
-- It can be used to analyze performance characteristics of different post types.

SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
GROUP BY 
    p.PostTypeId
ORDER BY 
    p.PostTypeId;
