-- Performance Benchmarking Query

-- This query retrieves the count of posts by type, average score per post type,
-- and total votes received, grouped by the PostTypeId, with a limit on the number of results for performance evaluation.

SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    TotalPosts DESC
LIMIT 100;  -- Adjust the limit for benchmarking
