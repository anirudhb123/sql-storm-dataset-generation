
WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        AVG(IFNULL(p.ViewCount, 0)) AS AverageViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(ph.PostId) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
),
FinalStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        IFNULL(ub.GoldCount, 0) AS GoldBadges,
        IFNULL(ub.SilverCount, 0) AS SilverBadges,
        IFNULL(ub.BronzeCount, 0) AS BronzeBadges,
        IFNULL(ps.TotalPosts, 0) AS TotalPosts,
        IFNULL(ps.TotalScore, 0) AS TotalScore,
        IFNULL(ps.AverageViews, 0) AS AverageViews,
        IFNULL(cp.ClosedCount, 0) AS ClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON u.Id = cp.UserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    TotalScore,
    AverageViews,
    ClosedPosts,
    CASE 
        WHEN TotalPosts > 10 AND ClosedPosts > 5 THEN 'Active Contributor'
        WHEN ClosedPosts = 0 THEN 'Non-Contributor'
        ELSE 'Moderate Contributor'
    END AS ContributorStatus
FROM 
    FinalStats
WHERE 
    (TotalPosts > 0 OR GoldBadges > 0 OR SilverBadges > 0 OR BronzeBadges > 0)
ORDER BY 
    TotalScore DESC, DisplayName;
