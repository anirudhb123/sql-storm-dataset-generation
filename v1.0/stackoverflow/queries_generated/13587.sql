-- Performance Benchmarking Query
-- This query retrieves the count of posts by type, average score, and average view count
-- It will also check for the number of active users contributing to posts

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS ActiveUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Considering posts from the last year
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
