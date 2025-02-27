WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostScoreRanked AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentClose
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.Badges,
    p.Title,
    ps.Score,
    ps.ScoreRank,
    cp.ClosedDate,
    cp.CloseReason
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostScoreRanked ps ON u.Id = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId AND cp.RecentClose = 1
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC, ps.Score DESC
LIMIT 100;

-- The above query provides a comprehensive view of users with high reputation,
-- their badge count, associated posts' scores and rankings, and information
-- about closed posts, including the reason for the closure.
