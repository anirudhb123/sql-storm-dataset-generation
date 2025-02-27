WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(u.Reputation, 0) AS Reputation,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.CreationDate >= NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts,
        MAX(phd.LastEdited) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistoryDetails phd ON phd.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.PostCount,
    ua.RecentPosts,
    ua.LastActivity,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    CASE 
        WHEN ua.Reputation IS NOT NULL AND ua.Reputation > 1000 THEN 'High Reputation User' 
        ELSE 'New or Low Reputation User' 
    END AS UserType
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.RankByScore <= 3
WHERE 
    ua.RecentPosts > 0
ORDER BY 
    ua.Reputation DESC, ua.PostCount DESC
LIMIT 10;
