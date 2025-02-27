-- Performance Benchmarking Query: 
-- This query retrieves the total number of posts, their average scores,
-- and the total number of votes per post type within a specified date range.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(v.Id IS NOT NULL) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31' -- Specify the date range here
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
