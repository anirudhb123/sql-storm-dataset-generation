WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2020-01-01'
    GROUP BY p.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        p.Title,
        COUNT(DISTINCT ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, p.Title
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Rank,
    rp.CommentCount,
    cq.CloseCount,
    cq.LastClosedDate,
    CASE 
        WHEN cq.CloseCount IS NULL THEN 'No Closures'
        ELSE 'Closed ' || cq.CloseCount || ' times on ' || COALESCE(TO_CHAR(cq.LastClosedDate, 'YYYY-MM-DD'), 'Unknown')
    END AS ClosureDetails
FROM UserStatistics us
JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN ClosedQuestions cq ON rp.PostId = cq.PostId
WHERE us.Reputation > 1000
ORDER BY us.Reputation DESC, rp.Score DESC;
