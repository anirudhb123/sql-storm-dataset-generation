WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        MAX(ph.CreationDate) AS RecentClosureDate,
        COUNT(*) AS ClosureCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Closing and Reopening actions
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
PostMetrics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.PostTypeId,
        us.Reputation,
        rp.Rank,
        cp.ClosureCount,
        COALESCE(cp.RecentClosureDate, CURRENT_TIMESTAMP) AS RecentClosureDate,
        CASE 
            WHEN cp.ClosureCount > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM RankedPosts rp
    JOIN UserStatistics us ON rp.OwnerUserId = us.UserId
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    p.Title,
    p.OwnerUserId,
    p.Reputation,
    p.PostTypeId,
    p.ClosureCount,
    p.RecentClosureDate,
    p.PostStatus
FROM PostMetrics p
WHERE (p.Reputation BETWEEN 1000 AND 5000 OR p.Rank = 1)
AND (p.PostTypeId = 1 OR p.PostTypeId = 2)  -- Questions and Answers only
ORDER BY p.Reputation DESC, p.ClosureCount ASC;
