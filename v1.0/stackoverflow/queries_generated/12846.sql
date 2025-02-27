-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        TotalScore,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalScore,
    U.QuestionCount,
    U.AnswerCount
FROM TopUsers U
WHERE Rank <= 10
ORDER BY U.TotalScore DESC;
