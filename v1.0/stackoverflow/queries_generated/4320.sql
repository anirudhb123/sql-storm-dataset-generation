WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        COUNT(DISTINCT b.Id) AS TotalBadgesEarned,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        au.DisplayName AS OwnerName,
        au.Reputation AS OwnerReputation,
        au.TotalBadgesEarned,
        au.GoldBadges,
        au.SilverBadges,
        au.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        ActiveUsers au ON rp.OwnerUserId = au.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.CommentCount,
    pm.OwnerName,
    pm.OwnerReputation,
    COALESCE(pm.GoldBadges, 0) AS GoldBadges,
    COALESCE(pm.SilverBadges, 0) AS SilverBadges,
    COALESCE(pm.BronzeBadges, 0) AS BronzeBadges
FROM 
    PostMetrics pm
WHERE 
    pm.Rank <= 3
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC;

SELECT COUNT(*) AS ClosedPostsCount
FROM Posts p
WHERE 
    p.PostTypeId = 1 
    AND EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10);
