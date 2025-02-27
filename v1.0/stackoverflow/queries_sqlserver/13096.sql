
WITH UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AveragePostScore,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT TOP 10
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    AveragePostScore,
    TotalComments
FROM 
    UserPostMetrics
ORDER BY 
    Reputation DESC, PostCount DESC;
