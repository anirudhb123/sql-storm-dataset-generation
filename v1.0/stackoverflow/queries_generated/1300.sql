WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),

UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostCommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
)

SELECT 
    up.DisplayName,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(pcs.CommentCount, 0) AS CommentCount,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.RankScore
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.PostId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostCommentStats pcs ON rp.PostId = pcs.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, 
    up.Reputation DESC;

WITH PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS TotalClosures
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.Id
)

SELECT
    p.Title,
    p.ViewCount,
    COALESCE(ps.ClosedPostsCount, 0) AS TotalClosures,
    SUM(ph.ChangeCount) AS TotalHistoryChanges
FROM 
    Posts p
LEFT JOIN 
    PostHistorySummary ph ON p.Id = ph.PostId
LEFT JOIN 
    ClosedPosts ps ON p.Id = ps.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 
    p.Title, p.ViewCount, ps.TotalClosuresCount
ORDER BY 
    TotalHistoryChanges DESC;
