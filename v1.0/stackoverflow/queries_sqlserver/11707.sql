
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalQuestions,
    up.TotalAnswers,
    up.TotalScore,
    ISNULL(ub.TotalBadges, 0) AS TotalBadges,
    ISNULL(ub.GoldBadges, 0) AS GoldBadges,
    ISNULL(ub.SilverBadges, 0) AS SilverBadges,
    ISNULL(ub.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserPosts up
LEFT JOIN 
    UserBadges ub ON up.UserId = ub.UserId
ORDER BY 
    up.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
