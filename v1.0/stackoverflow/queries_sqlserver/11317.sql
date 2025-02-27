
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    MAX(p.Score) AS TopPostScore,
    MAX(p.Title) AS TopPostTitle
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC, 
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
