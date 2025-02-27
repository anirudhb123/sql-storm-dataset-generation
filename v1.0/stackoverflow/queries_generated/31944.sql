WITH RECURSIVE TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Views,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
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
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
), UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN rp.PostRank = 1 THEN 1 ELSE 0 END), 0) AS RecentPostsCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(AVG(p.ViewCount), 0) AS AverageViews
    FROM 
        TopUsers u
    LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId 
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.RecentPostsCount,
    ups.GoldBadges + ups.SilverBadges + ups.BronzeBadges AS TotalBadges,
    ups.TotalScore,
    ups.AverageViews,
    CASE 
        WHEN ups.RecentPostsCount > 5 THEN 'Active'
        ELSE 'Less Active'
    END AS UserActivityLevel
FROM 
    UserPostStatistics ups
WHERE 
    ups.TotalScore > 100
ORDER BY 
    ups.TotalScore DESC
LIMIT 10;
