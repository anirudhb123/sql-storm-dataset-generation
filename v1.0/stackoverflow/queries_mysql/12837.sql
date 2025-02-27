
SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(u.Reputation) AS TotalUserReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-10-01 12:34:56'  
GROUP BY 
    p.PostTypeId, p.Score, u.Reputation
ORDER BY 
    TotalPosts DESC;
