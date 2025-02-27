WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' AND p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.Reputation,
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.LastAccessDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    up.UserId,
    up.BadgeCount,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(rp.CreationDate, 'No Posts Yet') AS LastPostDate,
    CASE 
        WHEN up.BadgeCount > 0 THEN 'Active Contributor'
        ELSE 'New User'
    END AS UserStatus
FROM ActiveUsers up
LEFT JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE up.UserRank <= 50
ORDER BY up.Reputation DESC, rp.Score DESC;
