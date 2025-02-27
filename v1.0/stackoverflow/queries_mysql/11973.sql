
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats, (SELECT @rank := 0) AS r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    U.DisplayName,
    T.Reputation,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalScore,
    T.Rank
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Rank;
