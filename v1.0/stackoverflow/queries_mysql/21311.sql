
WITH BadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(*) AS TotalBadges,
        MAX(Date) AS LastBadgeDate
    FROM Badges
    GROUP BY UserId
), 
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(ViewCount) AS AvgViews,
        MAX(Score) AS MaxScore
    FROM Posts
    WHERE CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR
    GROUP BY OwnerUserId
), 
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BC.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.AvgViews, 0) AS AvgViews,
        COALESCE(PS.MaxScore, 0) AS MaxScore,
        CASE 
            WHEN COALESCE(PS.TotalPosts, 0) = 0 THEN 'No Activity'
            WHEN COALESCE(PS.TotalQuestions, 0) > 0 AND COALESCE(PS.TotalAnswers, 0) > 0 THEN 'Active Contributor'
            ELSE 'Inactive or Passive'
        END AS ActivityLevel,
        UNIX_TIMESTAMP(COALESCE(BC.LastBadgeDate, '1970-01-01')) AS LastBadgeEpoch
    FROM Users U
    LEFT JOIN BadgeCounts BC ON U.Id = BC.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
), 
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBadges,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AvgViews,
        MaxScore,
        ActivityLevel,
        @rank := IF(@prev_total_posts = TotalPosts AND @prev_max_score = MaxScore, @rank, @rank + 1) AS UserRank,
        @prev_total_posts := TotalPosts,
        @prev_max_score := MaxScore
    FROM UserPerformance, (SELECT @rank := 0, @prev_total_posts := NULL, @prev_max_score := NULL) AS vars
    WHERE TotalBadges > 0
    ORDER BY TotalPosts DESC, MaxScore DESC
)

SELECT 
    R.UserId,
    R.DisplayName,
    R.TotalBadges,
    R.TotalPosts,
    R.TotalQuestions,
    R.TotalAnswers,
    R.AvgViews,
    R.MaxScore,
    R.ActivityLevel,
    R.UserRank,
    CASE 
        WHEN R.UserRank <= 10 THEN 'Top Contributor'
        WHEN R.UserRank BETWEEN 11 AND 50 THEN 'Notable Contributor'
        ELSE 'Regular Member'
    END AS RankCategory
FROM RankedUsers R
WHERE R.ActivityLevel != 'No Activity'
ORDER BY R.UserRank
LIMIT 5 OFFSET (SELECT COUNT(*) FROM RankedUsers R2 WHERE R2.ActivityLevel = 'Active Contributor');
