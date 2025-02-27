WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.ParentId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastActivePostDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation IS NOT NULL
    GROUP BY u.Id
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        u.Username,
        COALESCE(rp.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM RankedPosts rp
    JOIN Users u ON rp.PostId = u.Id 
    WHERE rp.Score > 10
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        COUNT(*) AS CloseEventCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId, ph.CreationDate
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.Score,
    hp.CommentCount,
    CASE WHEN cph.CloseEventCount IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus,
    ur.ReputationCategory,
    COALESCE(cph.CloseDate, 'No Closure') AS ClosureDate
FROM HighScorePosts hp
LEFT JOIN UserReputation ur ON hp.UserId = ur.UserId
LEFT JOIN ClosedPostHistory cph ON hp.PostId = cph.PostId
WHERE hp.CommentCount = (SELECT MAX(CommentCount) FROM HighScorePosts)
ORDER BY hp.Score DESC, ur.Reputation DESC
LIMIT 10;

-- The above query aims to evaluate the performance of posts considering various factors like user reputation,
-- post closure events, and aggregate comment counts. It combines common SQL constructs like CTEs, window functions, 
-- outer joins, and complex predicates while showcasing interesting relationships between users, posts, and their histories.
