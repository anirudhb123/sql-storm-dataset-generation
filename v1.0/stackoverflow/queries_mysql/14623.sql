
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
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
        TotalViews,
        TotalScore,
        @rank := @rank + 1 AS Rank
    FROM 
        UserMetrics, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)

SELECT 
    U.DisplayName,
    MU.Reputation,
    MU.PostCount,
    MU.QuestionCount,
    MU.AnswerCount,
    MU.TotalViews,
    MU.TotalScore
FROM 
    TopUsers MU
JOIN 
    Users U ON MU.UserId = U.Id
WHERE 
    MU.Rank <= 10
ORDER BY 
    MU.Rank;
