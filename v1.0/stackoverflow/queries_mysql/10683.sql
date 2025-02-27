
SELECT 
    p.PostTypeId,
    AVG(p.Score) AS AvgPostScore,
    COUNT(c.Id) AS TotalComments,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
GROUP BY 
    p.PostTypeId, p.Score, u.Reputation
ORDER BY 
    p.PostTypeId;
