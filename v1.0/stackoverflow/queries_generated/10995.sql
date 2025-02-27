-- Performance benchmarking query to evaluate the average response time for posts with the highest 
-- number of comments and their corresponding average scores, grouped by post type.

SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    AVG(p.Score) AS AverageScore,
    AVG(EXTRACT(EPOCH FROM (NOW() - p.CreationDate)) / 60) AS AverageResponseTimeInMinutes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
GROUP BY 
    pt.Name
ORDER BY 
    CommentCount DESC, AverageScore DESC
LIMIT 10; -- Limit results to top 10 post types
