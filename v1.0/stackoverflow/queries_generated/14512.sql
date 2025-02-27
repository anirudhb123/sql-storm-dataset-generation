-- Performance Benchmarking Query

-- This query retrieves the count of posts, average score of posts, 
-- and the total votes on posts grouped by PostType and OwnerUserId
SELECT 
    pt.Name AS PostType,
    p.OwnerUserId,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(v.Id IS NOT NULL) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name, p.OwnerUserId
ORDER BY 
    PostType, PostCount DESC;
