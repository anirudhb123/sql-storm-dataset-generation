WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) FILTER (WHERE c.Id IS NOT NULL) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year' AND 
        b.Class IN (1, 2) -- Focus on Gold and Silver badges
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        json_agg(ph.Comment ORDER BY ph.CreationDate) AS CommentsHistory,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Rank,
        rp.CommentCount,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        phd.CloseCount,
        phd.ReopenCount,
        phd.CommentsHistory,
        phd.LastChangeDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId
)
SELECT 
    *,
    CASE 
        WHEN BadgeCount IS NULL THEN 'No badges'
        ELSE CONCAT(BadgeCount, ' badges (highest class: ', COALESCE(HighestBadgeClass::text, 'None'), ')')
    END AS BadgeSummary,
    CASE 
        WHEN CloseCount > 0 AND ReopenCount = 0 THEN 'Closed'
        WHEN CloseCount = 0 AND ReopenCount > 0 THEN 'Reopened'
        WHEN CloseCount > 0 AND ReopenCount > 0 THEN 'Closed and Reopened'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN CommentsHistory IS NULL THEN 'No comments history'
        ELSE 'Comments history available'
    END AS CommentsHistoryStatus
FROM 
    FinalResults
WHERE 
    Rank <= 5 -- Top 5 posts per type based on score
ORDER BY 
    Rank, Score DESC;
