-- Performance benchmarking SQL query

-- This query will select the number of posts, users, comments, and votes, grouped by post type
-- It aims to assess the performance of various joins and aggregations in the StackOverflow schema

SELECT 
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    pt.Id;
