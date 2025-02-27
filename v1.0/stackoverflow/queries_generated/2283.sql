WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as PostRank
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) as GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) as SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) as BronzeBadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostsWithCloseReasons AS (
    SELECT
        ph.PostId,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes ct ON ph.Comment::INT = ct.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Only considering Close and Reopen events
    GROUP BY ph.PostId
)
SELECT
    up.DisplayName AS UserDisplayName,
    up.Reputation,
    rp.Title,
    rp.Score,
    ub.BadgeCount,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount,
    COALESCE(pc.CloseReasons, 'No close reasons') AS CloseReasons
FROM Users up
JOIN RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN UserBadges ub ON up.Id = ub.UserId
LEFT JOIN PostsWithCloseReasons pc ON rp.Id = pc.PostId
WHERE rp.PostRank = 1
AND up.Reputation > 1000
ORDER BY ub.BadgeCount DESC, rp.Score DESC
LIMIT 10;
