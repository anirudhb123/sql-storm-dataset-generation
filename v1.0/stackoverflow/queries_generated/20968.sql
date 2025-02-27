WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= now() - interval '1 year'
    AND 
        p.Score > 0
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
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryWithReason AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN cr.Name 
            ELSE NULL 
        END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(phwr.CloseReasons, 'No Close Reasons') AS ReasonsForStatus,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId IN (2, 3)) AS VoteCount,
    MAX(CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent ' || pt.Name 
        ELSE NULL 
    END) AS MostRecentPostType
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id = rp.PostId -- Filtering votes based on users
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistoryWithReason phwr ON rp.PostId = phwr.PostId
JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
WHERE 
    rp.Score > 10 
    AND (rp.ViewCount IS NOT NULL OR rp.ViewCount > 100)
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, ub.BadgeCount, pc.CommentCount, phwr.CloseReasons
ORDER BY 
    rp.Score DESC 
LIMIT 100;

### Explanation:
1. **Common Table Expressions (CTEs):** 
   - `RankedPosts` ranks posts created in the last year with a positive score.
   - `UserBadges` aggregates badges for each user.
   - `PostComments` counts comments for each post.
   - `PostHistoryWithReason` gathers close reasons from the PostHistory.
   
2. **Main Query:**
   - Joins the CTEs and other relevant tables to produce a comprehensive report on posts, including user badges, comments, and close reasons.
   - Uses `COALESCE` to handle NULL values gracefully.
   - Applies complex ranking and filtering (restricting posts by score and view count).
   - Includes a bizarre case expression to conditionally format the most recent post type.

This query showcases advanced SQL constructs, combining different SQL features into a single elaborative statement.
