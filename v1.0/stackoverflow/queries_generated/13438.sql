-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the count of posts by type, average score of posts,
-- and the total number of votes received per post type, ordered by post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(v.Id) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    pt.Name;
