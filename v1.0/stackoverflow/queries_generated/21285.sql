WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS BadgePoints, -- Assuming that badges a user has contribute to their points
        AVG(p.ViewCount) AS AvgPostViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        C.Name AS CloseReason,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseVoteCount
    FROM PostHistory ph
    JOIN CloseReasonTypes C ON ph.Comment::jsonb @> jsonb_build_array(C.Id::jsonb) 
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId, ph.CreationDate, C.Name
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    us.TotalPosts,
    us.TotalScore,
    us.BadgePoints,
    us.AvgPostViewCount,
    cp.CloseReason,
    cp.CloseVoteCount
FROM RankedPosts rp
JOIN UserStats us ON rp.OwnerUserId = us.UserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.UpvoteCount - rp.DownvoteCount) > 5 -- Posts should have a net positive vote
    AND (cp.CloseVoteCount IS NULL OR cp.CloseVoteCount = 0) -- Filter out closed posts
ORDER BY 
    rp.Score DESC,
    us.TotalScore DESC,
    us.TotalPosts DESC
LIMIT 100;
This SQL query includes multiple advanced SQL constructs and operations:
- Common Table Expressions (CTEs) are used to modularize data fetching by breaking down the query into smaller, logical units: `RankedPosts`, `UserStats`, and `ClosedPosts`.
- Window functions (`ROW_NUMBER()`) are applied to rank posts by score for each user.
- Subqueries fetch upvote and downvote counts for each post.
- A variety of JOIN operations (inner and outer) are utilized across multiple tables.
- Complex filtering is implemented concerning post metrics (like net votes) and post state (closed or not).
- It overall pulls together user statistics, ranked posts, and close reasons, demonstrating an elaborate traversal across the schema.
