-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the total number of posts, the average score of posts,
-- and the total number of comments per post type, along with the total number of users.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT c.Id) AS TotalComments,
    (SELECT COUNT(DISTINCT u.Id) FROM Users u) AS TotalUsers
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

-- Additionally, this query can be used to benchmark performance 
-- by measuring execution time and resource utilization.
