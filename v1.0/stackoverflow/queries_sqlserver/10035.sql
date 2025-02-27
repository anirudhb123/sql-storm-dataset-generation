
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
