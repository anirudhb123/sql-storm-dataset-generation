
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopBadgers AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.TotalViews,
        UA.AvgScore,
        TB.BadgeCount,
        @rank_by_views := IF(@prev_views = UA.TotalViews, @rank_by_views, @row_number) AS RankByViews,
        @prev_views := UA.TotalViews,
        @row_number := @row_number + 1
    FROM 
        UserActivity UA
    LEFT JOIN 
        TopBadgers TB ON UA.UserId = TB.UserId,
        (SELECT @row_number := 0, @prev_views := NULL) AS vars
    ORDER BY 
        UA.TotalViews DESC
),
RankedUsersScore AS (
    SELECT 
        R.*,
        @rank_by_score := IF(@prev_score = R.AvgScore, @rank_by_score, @row_number_score) AS RankByScore,
        @prev_score := R.AvgScore,
        @row_number_score := @row_number_score + 1
    FROM 
        RankedUsers R,
        (SELECT @row_number_score := 0, @prev_score := NULL) AS vars
    ORDER BY 
        R.AvgScore DESC
)
SELECT 
    R.DisplayName,
    R.TotalPosts,
    R.TotalQuestions,
    R.TotalAnswers,
    R.TotalViews,
    R.AvgScore,
    COALESCE(R.BadgeCount, 0) AS BadgeCount,
    R.RankByViews,
    R.RankByScore
FROM 
    RankedUsersScore R
WHERE 
    R.TotalPosts > 10
    AND (R.RankByViews <= 10 OR R.RankByScore <= 10)
ORDER BY 
    R.RankByViews, R.RankByScore;
