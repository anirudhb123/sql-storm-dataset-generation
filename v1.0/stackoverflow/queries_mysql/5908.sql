
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        SUM(CASE WHEN P.ViewCount > 0 THEN 1 ELSE 0 END) AS PostsWithViews,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PositiveScores,
        PostsWithViews,
        AvgViewCount,
        (SELECT COUNT(*) FROM (
            SELECT UserId, 
                   @rank := IF(@prev_value = TotalPosts, @rank, @rank + 1) AS PostRank,
                   @prev_value := TotalPosts
            FROM (
                SELECT UserId, TotalPosts
                FROM UserActivity
                ORDER BY TotalPosts DESC
            ) AS ranked
            CROSS JOIN (SELECT @rank := 0, @prev_value := NULL) AS init
        ) AS ranked_with_ranks
        ORDER BY PostRank) AS PostRank
    FROM UserActivity
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.PositiveScores,
    TU.PostsWithViews,
    TU.AvgViewCount,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = TU.UserId) AS BadgeCount
FROM TopUsers TU
WHERE TU.PostRank <= 10
ORDER BY TU.TotalPosts DESC;
