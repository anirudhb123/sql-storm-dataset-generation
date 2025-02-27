-- Performance Benchmarking Query

-- This query retrieves the count of posts, the average score of posts, and the number of comments on posts
-- grouped by PostType and ordered by the number of posts.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AverageScore, 
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(Id) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
