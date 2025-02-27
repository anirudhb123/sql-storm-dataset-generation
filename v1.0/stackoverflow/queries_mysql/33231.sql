
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.LastActivityDate, 
        p.Score, 
        p.OwnerUserId,
        @row_num := IF(@prev_id = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_id := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_num := 0, @prev_id := NULL) r
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount, 
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ud.DisplayName,
        ud.Reputation,
        ud.BadgeCount,
        ud.GoldBadges,
        ud.SilverBadges,
        ud.BronzeBadges,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.LastClosedDate, '1900-01-01') AS LastClosedDate,
        rp.ViewCount
    FROM 
        RankedPosts rp
    JOIN 
        UserDetails ud ON rp.OwnerUserId = ud.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pm.Title,
    pm.DisplayName,
    pm.Reputation,
    pm.BadgeCount,
    pm.GoldBadges,
    pm.SilverBadges,
    pm.BronzeBadges,
    pm.CloseCount,
    pm.LastClosedDate,
    pm.ViewCount
FROM 
    PostMetrics pm
WHERE 
    pm.CloseCount > 0 
    AND pm.Reputation >= 1000 
ORDER BY 
    pm.ViewCount DESC, 
    pm.Reputation DESC
LIMIT 10;
