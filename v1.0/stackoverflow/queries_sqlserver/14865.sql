
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS PostCount,
    SUM(P.Score) AS TotalScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
