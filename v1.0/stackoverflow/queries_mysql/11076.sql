
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalViews,
        TotalScore,
        @row_num := @row_num + 1 AS Rank
    FROM UserPostStats, (SELECT @row_num := 0) AS rn
    ORDER BY TotalScore DESC
)
SELECT * 
FROM TopUsers
WHERE Rank <= 10;
