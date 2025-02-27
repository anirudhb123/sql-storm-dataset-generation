WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank,
        COALESCE(UPPER(p.Body), 'No Content') AS BodyContent,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.Body, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
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
        ph.PostHistoryTypeId, 
        ph.CreationDate AS HistoryDate, 
        COALESCE(c.Name, 'No Reason') AS CloseReason,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- only relevant events
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.BodyContent,
    rp.Score,
    rp.Rank,
    ub.BadgeCount,
    ub.BadgeNames,
    ph.HistoryCount,
    ph.CloseReason,
    CASE 
        WHEN ph.HistoryCount IS NULL THEN 'No History Events'
        WHEN ph.HistoryCount > 5 THEN 'Frequently Edited'
        ELSE 'Seldom Updated'
    END AS UpdateFrequency,
    CASE 
        WHEN rp.BodyContent IS NULL THEN 'Content Missing'
        WHEN rp.BodyContent LIKE '%error%' THEN 'Potential Error Notice'
        ELSE 'Content Present'
    END AS ContentStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 3  -- Top 3 posts per user
ORDER BY 
    rp.Score DESC NULLS LAST,
    rp.CreationDate ASC;
This SQL query does the following:
- Uses Common Table Expressions (CTEs) to prepare ranked posts, user badges, and post history details.
- Includes outer joins to incorporate related data even if some of it might be null.
- Implements a window function to rank posts based on their score for each user.
- Uses string aggregation to gather all tags and badges concisely for output.
- Incorporates NULL-related logic in the final SELECT statement to provide meaningful status updates based on available data.
- The query applies filters and sorting to yield a ranking of top posts for users while bundling in badge information and history insight.
