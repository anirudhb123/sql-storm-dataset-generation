-- Performance benchmarking query for the StackOverflow schema
-- This query retrieves the number of posts, average score, and total votes for each post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(v.Id IS NOT NULL) AS TotalVotes
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
