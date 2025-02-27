WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
RecentActivity AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    WHERE c.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ub.BadgeNames, 'No badges') AS UserBadges,
    ra.CommentCount,
    ra.LastCommentDate
FROM RankedPosts rp
LEFT JOIN Users u ON u.Id = rp.OwnerUserId
LEFT JOIN UserBadges ub ON ub.UserId = u.Id
LEFT JOIN RecentActivity ra ON ra.PostId = rp.PostId
WHERE rp.Rank <= 5
AND (ra.CommentCount IS NULL OR ra.CommentCount > 5)
ORDER BY rp.ViewCount DESC, rp.Score DESC;
