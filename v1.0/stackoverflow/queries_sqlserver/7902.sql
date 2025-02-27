
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ISNULL(ps.TotalPosts, 0) AS TotalPosts,
    ISNULL(ps.Questions, 0) AS Questions,
    ISNULL(ps.Answers, 0) AS Answers,
    ISNULL(ps.TotalViews, 0) AS TotalViews,
    ISNULL(ps.TotalScore, 0) AS TotalScore,
    (CASE 
        WHEN ISNULL(ps.TotalViews, 0) > 0 THEN (CAST(ISNULL(ps.TotalScore, 0) AS FLOAT) / ISNULL(ps.TotalViews, 0)) * 100
        ELSE 0
    END) AS EngagementRate
FROM 
    UserBadges ub
LEFT JOIN 
    PostStats ps ON ub.UserId = ps.OwnerUserId
ORDER BY 
    EngagementRate DESC, ub.BadgeCount DESC;
