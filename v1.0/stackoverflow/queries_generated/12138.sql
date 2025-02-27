-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the count of posts by type, the average vote score, and the total number of comments for each post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(v.Score) AS AverageVoteScore,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
