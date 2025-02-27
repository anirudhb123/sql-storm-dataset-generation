
WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        AVG(P.ViewCount) AS AverageViews
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
)
SELECT
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalScore,
    TotalViews,
    AverageScore,
    AverageViews
FROM
    UserPostStats
ORDER BY
    TotalScore DESC
LIMIT 10;
