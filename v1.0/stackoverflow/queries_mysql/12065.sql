
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        @rank := IF(@prevPostCount = PostCount, @rank, @rank + 1) AS UserRank,
        @prevPostCount := PostCount
    FROM UserPostCounts, (SELECT @rank := 0, @prevPostCount := NULL) AS vars
    ORDER BY PostCount DESC
)
SELECT 
    TU.UserRank,
    TU.DisplayName,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    U.Reputation,
    U.Views
FROM TopUsers TU
JOIN Users U ON TU.UserId = U.Id
WHERE TU.UserRank <= 10
ORDER BY TU.UserRank;
