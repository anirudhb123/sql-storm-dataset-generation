SELECT 
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    SUM(COALESCE(Vs.Score, 0)) AS TotalVotes,
    AVG(COALESCE(P.Score, 0)) AS AverageScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes Vs ON P.Id = Vs.PostId
GROUP BY 
    U.Id
ORDER BY 
    PostCount DESC
LIMIT 10;
