WITH RankedUsers AS (
    SELECT 
        Users.Id, 
        Users.DisplayName, 
        Users.Reputation, 
        ROW_NUMBER() OVER (PARTITION BY Users.Location ORDER BY Users.Reputation DESC) AS Rank
    FROM 
        Users
    WHERE 
        Users.Reputation > 100
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AvgViews,
    ps.TotalQuestions,
    ps.TotalAnswers,
    r.Rank
FROM 
    RankedUsers r
LEFT JOIN 
    UserBadges ub ON r.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON r.Id = ps.OwnerUserId
WHERE 
    r.Rank <= 3
ORDER BY 
    r.Location, 
    r.Rank;
