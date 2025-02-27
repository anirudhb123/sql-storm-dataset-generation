WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadgeCounts AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostWithUsers AS (
    SELECT rp.Id AS PostId, rp.Title, rp.CreationDate, rp.Score, u.DisplayName AS OwnerDisplayName
    FROM RankedPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE rp.PostRank = 1
),
RecentComments AS (
    SELECT c.PostId, COUNT(c.Id) AS CommentCount
    FROM Comments c
    WHERE c.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY c.PostId
)
SELECT pw.Title, pw.CreationDate, pw.Score, pw.OwnerDisplayName, 
       COALESCE(rc.CommentCount, 0) AS RecentCommentCount, 
       COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
FROM PostWithUsers pw
LEFT JOIN RecentComments rc ON pw.PostId = rc.PostId
LEFT JOIN UserBadgeCounts ub ON pw.OwnerDisplayName = ub.UserId
ORDER BY pw.Score DESC, pw.CreationDate ASC
LIMIT 100;
