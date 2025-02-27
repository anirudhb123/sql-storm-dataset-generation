WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        pm.UserId,
        COUNT(pc.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT pm.Id) AS PostCount
    FROM 
        Posts pm
    LEFT JOIN 
        Comments pc ON pm.Id = pc.PostId
    LEFT JOIN 
        Votes v ON pm.Id = v.PostId
    GROUP BY 
        pm.UserId
),
ClosedPosts AS (
    SELECT 
        PostId, 
        COUNT(*) AS CloseCount 
    FROM 
        PostHistory 
    WHERE 
        PostHistoryTypeId = 10
    GROUP BY 
        PostId
)
SELECT 
    u.DisplayName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pa.CommentCount,
    pa.Upvotes,
    pa.TotalViews,
    pp.RecentPostRank,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM 
    Users u
JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    PostActivity pa ON u.Id = pa.UserId
LEFT JOIN 
    RankedPosts pp ON u.Id = pp.OwnerUserId AND pp.RecentPostRank = 1
LEFT JOIN 
    ClosedPosts cp ON pp.PostId = cp.PostId
WHERE 
    (ub.GoldBadges > 0 OR ub.SilverBadges > 0 OR ub.BronzeBadges > 0)
    AND (pa.CommentCount > 10 OR pa.TotalViews > 1000)
ORDER BY 
    pa.TotalViews DESC, 
    ub.GoldBadges DESC, 
    pa.CommentCount DESC
LIMIT 100;
