-- Performance Benchmarking Query
-- This query retrieves the count of posts by type, the average score of those posts,
-- as well as the users' reputation and their badge counts to assess query performance.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    u.Reputation AS UserReputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    pt.Name, u.Reputation
ORDER BY 
    PostCount DESC;
