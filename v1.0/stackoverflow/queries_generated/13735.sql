-- Performance Benchmarking Query: Retrieve users with their total post count, average score, and total reputation
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPostCount,
    AVG(P.Score) AS AverageScore,
    U.Reputation
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPostCount DESC, AverageScore DESC;
