WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
FilteredComments AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM 
        Comments
    WHERE 
        CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        PostId
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE NULL END) AS ClosureCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(fc.TotalComments, 0) AS FilteredCommentCount,
    COALESCE(fc.NegativeComments, 0) AS NegativeCommentCount,
    COALESCE(bc.GoldBadges, 0) AS GoldBadges,
    COALESCE(bc.SilverBadges, 0) AS SilverBadges,
    COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
    phs.ClosureCount,
    phs.LastEditedDate,
    CASE
        WHEN rp.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN phs.ClosureCount > 0 THEN 
            'Closed (' || phs.ClosureCount || ' times)'
        ELSE 
            'Open'
    END AS ClosureStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredComments fc ON rp.PostId = fc.PostId
LEFT JOIN 
    BadgeCounts bc ON rp.OwnerUserId = bc.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
    AND EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2)  -- At least one upvote
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC
LIMIT 50;
