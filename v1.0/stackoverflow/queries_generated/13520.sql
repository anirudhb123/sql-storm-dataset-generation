-- Performance Benchmarking Query
WITH UserAggregates AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id
)
SELECT 
    UA.UserId,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalScore,
    UA.BadgeCount,
    UA.TotalBounty,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate
FROM 
    UserAggregates UA
JOIN 
    Users U ON UA.UserId = U.Id
ORDER BY 
    UA.TotalScore DESC, 
    UA.PostCount DESC;
