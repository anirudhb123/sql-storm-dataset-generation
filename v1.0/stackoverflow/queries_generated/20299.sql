WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.CreationDate DESC) AS RankByCreation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    COUNT(DISTINCT rp.PostId) AS RecentPosts,
    COUNT(DISTINCT cph.PostId) FILTER (WHERE cph.CloseRank = 1) AS MostRecentClosedPosts,
    SUM(CASE WHEN rp.RankByCreation = 1 THEN rp.ViewCount ELSE 0 END) AS MostViewedRecentPost,
    STRING_AGG(DISTINCT CASE WHEN cph.CloseRank = 1 THEN cph.CloseReason ELSE NULL END, ', ') AS CloseReasons
FROM 
    UserStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.RankByScore > 2
LEFT JOIN 
    ClosedPostHistory cph ON rp.PostId = cph.PostId
GROUP BY 
    up.UserId, up.DisplayName, up.GoldBadges, up.SilverBadges, up.BronzeBadges
ORDER BY 
    RecentPosts DESC, MostViewedRecentPost DESC
LIMIT 10;

-- This SQL query benchmarks user activity, including recent posts, 
-- badges received, and closed posts, providing valuable performance metrics.
