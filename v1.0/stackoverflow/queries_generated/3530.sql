WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        postId, 
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY postId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.UserId,
    us.Reputation,
    us.CommentCount,
    us.BadgeCount,
    COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount
FROM RankedPosts rp
JOIN Users us ON us.Id = rp.PostId
LEFT JOIN ClosedPosts cp ON cp.postId = rp.PostId
WHERE rp.RankByScore <= 10
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

-- Using set operator to include posts with a high number of views regardless of type
UNION ALL

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    NULL AS UserId,
    NULL AS Reputation,
    NULL AS CommentCount,
    NULL AS BadgeCount,
    0 AS CloseVoteCount
FROM Posts p
WHERE p.ViewCount > 1000
ORDER BY ViewCount DESC
LIMIT 50;
