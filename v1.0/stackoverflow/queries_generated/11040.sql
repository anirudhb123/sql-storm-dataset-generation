-- Performance Benchmarking Query for StackOverflow Schema

-- This query fetches the total number of posts, their average score, 
-- the number of comments for each post type, and the total number of users.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers
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
    TotalPosts DESC;
