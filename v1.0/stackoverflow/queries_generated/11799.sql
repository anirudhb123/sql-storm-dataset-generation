-- Performance benchmarking query: Get the count of posts with their types, users along with their reputation,
-- and the average score of posts grouped by post type and user reputation.

SELECT 
    pt.Name AS PostType,
    u.Reputation AS UserReputation,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, 
    u.Reputation
ORDER BY 
    pt.Name, 
    u.Reputation;
