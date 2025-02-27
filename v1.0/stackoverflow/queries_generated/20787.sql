WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(p.ClosedDate, '9999-12-31'::timestamp) AS CloseDate,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryExtended AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.OwnerDisplayName,
    RANK() OVER (ORDER BY ph.FirstEditDate) AS EditRanking,
    ph.EditCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 0 
        ELSE ub.BadgeCount 
    END AS UserBadgeCount,
    ph.LastEditDate,
    p.PostStatus
FROM 
    RankedPosts p
LEFT JOIN 
    PostHistoryExtended ph ON p.PostId = ph.PostId
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
WHERE 
    (p.Score > 5 OR p.ViewCount > 100)
    AND (p.PostStatus = 'Active' OR (p.PostStatus = 'Closed' AND ph.EditCount > 0))
ORDER BY 
    p.Score DESC, 
    p.ViewCount ASC
LIMIT 100 OFFSET ((RANDOM() * 10)::int);  -- Random offset for pagination

### Explanation:

1. **Common Table Expressions (CTEs)**:
    - **RankedPosts**: Ranks posts by their creation date for each user while selecting relevant fields. Closed posts are checked with a `COALESCE` to ensure we have a comparably high futuristic timestamp.
    - **UserBadges**: Counts badges for users, separating them into Gold, Silver, and Bronze badges.
    - **PostHistoryExtended**: Aggregates the post history for edit dates and counts.

2. **Main Select Query**: Joins RankedPosts with PostHistoryExtended and UserBadges, applying multiple conditions to filter the final results based on score and view count while checking the post’s status as well.

3. **Window Functions**: Utilizes `ROW_NUMBER()` and `RANK()`, allowing sorting and ranking of rows within partitioned data.

4. **UNIQUE Pagination**: Uses a random offset to create a unique pagination experience for tablet views.

5. **Complicated Predicate Logic**: Combines various predicates in the `WHERE` clause to filter posts based on their status and interaction level. 

This query serves to provide insights into user engagement through posts, taking into account their activity history and badge count, offering a mix of ranking and summarization across different metrics.
