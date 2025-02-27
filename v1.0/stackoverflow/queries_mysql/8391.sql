
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
UserRanked AS (
    SELECT 
        us.UserId,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalViews,
        us.TotalScore,
        us.AvgScore,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        @rankScore := IF(@prevScore = us.TotalScore, @rankScore, @currScore := @currScore + 1) AS ScoreRank,
        @prevScore := us.TotalScore,
        @rankPosts := IF(@prevPosts = us.TotalPosts, @rankPosts, @currPosts := @currPosts + 1) AS PostsRank,
        @prevPosts := us.TotalPosts
    FROM 
        UserStatistics us,
        (SELECT @currScore := 0, @rankScore := 0, @prevScore := NULL, @currPosts := 0, @rankPosts := 0, @prevPosts := NULL) AS vars
    ORDER BY 
        us.TotalScore DESC, us.TotalPosts DESC
)
SELECT 
    ur.UserId,
    ur.TotalPosts,
    ur.TotalQuestions,
    ur.TotalAnswers,
    ur.TotalViews,
    ur.TotalScore,
    ur.AvgScore,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ur.ScoreRank,
    ur.PostsRank,
    @viewsRank := IF(@prevViews = ur.TotalViews, @viewsRank, @currViews := @currViews + 1) AS ViewsRank,
    @prevViews := ur.TotalViews
FROM 
    UserRanked ur,
    (SELECT @currViews := 0, @viewsRank := 0, @prevViews := NULL) AS vars
WHERE 
    ur.TotalPosts > 10
ORDER BY 
    ur.TotalScore DESC, 
    ur.TotalPosts DESC;
