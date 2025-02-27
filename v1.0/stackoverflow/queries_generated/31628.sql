WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.ClosedDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Last year
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
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
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
AggregatePostHistory AS (
    SELECT 
        PostId,
        SUM(CASE WHEN PostHistoryTypeId = 10 THEN ChangeCount END) AS CloseCount,
        SUM(CASE WHEN PostHistoryTypeId = 11 THEN ChangeCount END) AS ReopenCount,
        SUM(CASE WHEN PostHistoryTypeId = 12 THEN ChangeCount END) AS DeleteCount
    FROM 
        PostHistoryStats
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.ClosedDate,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(aph.CloseCount, 0) AS TotalCloseCount,
    COALESCE(aph.ReopenCount, 0) AS TotalReopenCount,
    COALESCE(aph.DeleteCount, 0) AS TotalDeleteCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    AggregatePostHistory aph ON rp.PostId = aph.PostId
WHERE 
    rp.OwnerRank = 1 -- Get only the latest post per user
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
This query performs several advanced SQL techniques. Specifically:

1. **Common Table Expressions** (CTEs) are used for organizing and breaking down complex calculations for ranked posts, badge aggregation by users, and post history statistics.
2. **Window Functions** using `DENSE_RANK()` to determine the most recent posts for each user.
3. **Conditional Aggregation** to count badges categorized by their class.
4. **Outer Joins** to gather information from badges and post history without excluding posts that may not have corresponding records.
5. **Complicated predicates** in the `WHERE` clause to filter on multiple conditions.
6. **NULL Logic** with `COALESCE` to take care of potential NULLs in counted statistics.
7. **ORDER BY clause** to rank results primarily by score and secondarily by view count for more insightful performance analysis.
