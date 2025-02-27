
SELECT 
    Users.DisplayName,
    COUNT(Posts.Id) AS PostCount,
    SUM(Posts.Score) AS TotalScore
FROM 
    Users
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
GROUP BY 
    Users.DisplayName
ORDER BY 
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
