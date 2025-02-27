WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.LastActivityDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank
    FROM 
        Posts p
),
CommentStats AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveComments,
        COALESCE(SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativeComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryAgg AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCounts,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCounts,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditSuggestedCounts,
        STRING_AGG(ph.Comment, '; ') AS RelatedComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.LastActivityDate,
    cs.TotalComments,
    cs.PositiveComments,
    cs.NegativeComments,
    COALESCE(b.TotalBadges, 0) AS TotalBadges,
    COALESCE(b.HighestBadgeClass, 0) AS HighestBadgeClass,
    COALESCE(ph.CloseReopenCounts, 0) AS CloseReopenCounts,
    COALESCE(ph.DeleteCounts, 0) AS DeleteCounts,
    COALESCE(ph.EditSuggestedCounts, 0) AS EditSuggestedCounts,
    ph.RelatedComments
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentStats cs ON rp.PostId = cs.PostId
LEFT JOIN 
    BadgeStats b ON EXISTS (SELECT 1 FROM Users u WHERE u.Id = b.UserId AND u.Reputation >= 1000)
LEFT JOIN 
    PostHistoryAgg ph ON rp.PostId = ph.PostId
WHERE 
    (rp.PostTypeId = 1 AND rp.Score > 10)
    OR (rp.PostTypeId = 2 AND cs.TotalComments > 0 AND cs.PositiveComments > cs.NegativeComments)
ORDER BY 
    rp.LastActivityDate DESC, 
    CASE WHEN rp.PostTypeId = 1 THEN 1 ELSE 2 END,
    rp.ScoreRank;
