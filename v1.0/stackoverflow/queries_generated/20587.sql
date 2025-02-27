WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
BadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId, 
    up.DisplayName,
    bp.PostId,
    bp.Title,
    bp.CreationDate,
    bp.Score,
    bp.ViewCount,
    bp.CommentCount,
    COALESCE(bd.GoldBadges, 0) AS GoldBadges,
    COALESCE(bd.SilverBadges, 0) AS SilverBadges,
    COALESCE(bd.BronzeBadges, 0) AS BronzeBadges,
    ph.PostHistoryTypes,
    ph.LastModified,
    CASE 
        WHEN bp.Rank = 1 THEN 'Top Post in Type'
        ELSE 'Other Post'
    END AS PostRankStatus
FROM 
    RankedPosts bp
JOIN 
    BadgeStats bd ON bd.UserId = bp.OwnerUserId
LEFT JOIN 
    PostHistoryDetails ph ON ph.PostId = bp.PostId
WHERE 
    bp.Score > (SELECT AVG(Score) FROM Posts) 
    AND (bp.ViewCount IS NULL OR bp.ViewCount > 100)
    AND (bp.CreationDate >= NOW() - INTERVAL '30 days')
ORDER BY 
    bp.Score DESC,
    bp.CreationDate
FETCH FIRST 100 ROWS ONLY;

This query combines multiple advanced SQL constructs including Common Table Expressions (CTEs) for post ranking and badge statistics, correlated aggregations, outer joins, and intricate conditional logic. It pulls data from various tables while applying filters and aggregations to meet specific conditions, demonstrating both complexity and performance considerations.
