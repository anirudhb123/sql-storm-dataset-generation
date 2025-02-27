
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.Score, 0)) AS TotalPostScore,
        SUM(IFNULL(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(IFNULL(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(IFNULL(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END, 0)) AS WikiCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        TotalPostScore,
        QuestionCount,
        AnswerCount,
        WikiCount,
        @rank := @rank + 1 AS Rank
    FROM UserStats, (SELECT @rank := 0) r
    ORDER BY TotalPostScore DESC
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    TotalPostScore,
    QuestionCount,
    AnswerCount,
    WikiCount,
    Rank
FROM TopUsers
WHERE Rank <= 10
ORDER BY TotalPostScore DESC;
