-- Performance benchmarking query
WITH UserStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(CASE WHEN PostTypeId = 6 THEN 1 ELSE 0 END) AS ModeratorNominations,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, Reputation
),

BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    us.UserId,
    us.Reputation,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.Wikis,
    us.TagWikis,
    us.ModeratorNominations,
    us.TotalViews,
    us.TotalScore,
    COALESCE(bs.TotalBadges, 0) AS TotalBadges,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserStats us
LEFT JOIN 
    BadgeStats bs ON us.UserId = bs.UserId
ORDER BY 
    us.Reputation DESC, us.TotalPosts DESC;
