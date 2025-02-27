
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    AVG(p.Score) AS AverageScore,
    COUNT(p.Id) AS PostCount,
    u.Reputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    AverageScore DESC, PostCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
