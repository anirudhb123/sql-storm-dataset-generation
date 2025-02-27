-- Performance Benchmarking Query

-- This query selects the total count of posts, average score of posts,
-- total number of comments and total number of users, grouped by 
-- post type, to assess performance metrics across different categories.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT c.Id) AS TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
