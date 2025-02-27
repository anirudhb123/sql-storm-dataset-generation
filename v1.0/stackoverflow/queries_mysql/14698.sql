
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(CM.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        TotalViews,
        TotalComments,
        @rank := @rank + 1 AS Rank
    FROM UserActivity, (SELECT @rank := 0) r
    ORDER BY TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalScore,
    TotalViews,
    TotalComments,
    Rank
FROM TopUsers
WHERE Rank <= 10;
