-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the count of posts by type, average score of posts, and total number of comments
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(c.CommentCount) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Query execution time can be measured and analyzed based on the number of rows in Posts and Comments tables.
