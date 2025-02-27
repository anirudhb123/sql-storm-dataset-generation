
SELECT 
    COUNT(P.Id) AS TotalPosts,
    SUM(P.ViewCount) AS TotalViewCount,
    SUM(P.Score) AS TotalScore,
    AVG(U.Reputation) AS AverageUserReputation,
    (SELECT TOP 1 
        B.Name 
     FROM 
        Badges B 
     WHERE 
        B.UserId = U.Id 
     ORDER BY 
        B.Date DESC) AS RecentBadge
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
GROUP BY 
    U.Id, U.Reputation
ORDER BY 
    TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
