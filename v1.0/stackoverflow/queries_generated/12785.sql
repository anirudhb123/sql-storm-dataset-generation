-- Performance benchmarking query to analyze average post score by post type and user reputation
SELECT 
    pt.Name AS PostType, 
    AVG(p.Score) AS AverageScore, 
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Considering posts from the last year
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
