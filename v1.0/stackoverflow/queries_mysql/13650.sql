
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        TotalViews,
        AcceptedAnswers,
        @Rank := @Rank + 1 AS Rank
    FROM
        UserStats, (SELECT @Rank := 0) AS r
    ORDER BY
        TotalScore DESC
)
SELECT
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    AcceptedAnswers
FROM
    TopUsers
WHERE
    Rank <= 10;
