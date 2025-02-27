
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
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
        TotalViews,
        TotalScore,
        @row_number := IF(@prev_total_score = TotalScore, @row_number, @row_number + 1) AS Rank,
        @prev_total_score := TotalScore
    FROM UserStats, (SELECT @row_number := 0, @prev_total_score := NULL) AS vars
    ORDER BY TotalScore DESC
)

SELECT
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    Rank
FROM TopUsers
WHERE Rank <= 10;
