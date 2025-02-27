WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PositiveScorePosts,
        PopularPosts,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalQuestions DESC) AS QuestionRank,
        RANK() OVER (ORDER BY PositiveScorePosts DESC) AS PositiveScoreRank
    FROM 
        UserPostStats
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.PositiveScorePosts,
    UPS.PopularPosts,
    BS.TotalBadges,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges,
    LEAST(UPS.PostRank, UPS.QuestionRank, UPS.PositiveScoreRank) AS GeneralRank
FROM 
    TopUsers u
JOIN 
    UserPostStats UPS ON u.UserId = UPS.UserId
LEFT JOIN 
    BadgeStats BS ON u.UserId = BS.UserId
WHERE 
    UPS.TotalPosts > 10
ORDER BY 
    GeneralRank 
LIMIT 50;
