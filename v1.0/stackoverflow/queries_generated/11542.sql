-- Performance Benchmarking Query

-- This query retrieves the count of posts by each post type, average score of posts,
-- and the total number of comments and votes associated with those posts.
-- It will help analyze the performance of posts in different categories.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
