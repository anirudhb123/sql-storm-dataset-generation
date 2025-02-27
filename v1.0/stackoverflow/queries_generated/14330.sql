-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves aggregated data from multiple tables to benchmark performance
-- It includes the count of posts, the average vote score, and the number of comments grouped by post type

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(v.Score) AS AverageVoteScore, 
    COUNT(c.Id) AS TotalComments
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Consider only posts created in the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
