-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the average score of posts, the total number of posts, 
-- and the number of comments grouped by post type over a specified timeframe.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days' -- last 30 days
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
