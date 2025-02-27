WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
UserBadges AS (
    SELECT b.UserId, COUNT(*) AS BadgeCount
    FROM Badges b
    WHERE b.Class = 1 -- Count only Gold badges
    GROUP BY b.UserId
),
PostHistoryInfo AS (
    SELECT ph.PostId,
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
           COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT rp.Title,
       rp.CreationDate,
       rp.Score,
       rp.CommentCount,
       rp.Upvotes,
       rp.Downvotes,
       ub.BadgeCount,
       COALESCE(phi.LastClosedDate, 'Never Closed') AS LastClosed,
       phi.DeleteCount
FROM RankedPosts rp
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN PostHistoryInfo phi ON rp.Id = phi.PostId
WHERE rp.rn = 1
ORDER BY rp.Score DESC, rp.CommentCount DESC;
