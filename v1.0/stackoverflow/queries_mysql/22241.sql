
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.ViewCount,
           @row_num := IF(@prev_post = p.PostTypeId, @row_num + 1, 1) AS Rank,
           @prev_post := p.PostTypeId,
           COUNT(c.Id) AS CommentCount,
           AVG(v.BountyAmount) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    CROSS JOIN (SELECT @row_num := 0, @prev_post := NULL) AS init
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
RecentPostHistory AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.UserId,
           ph.CreationDate,
           @history_row_num := IF(@prev_post_history = ph.PostId, @history_row_num + 1, 1) AS HistoryRank,
           @prev_post_history := ph.PostId
    FROM PostHistory ph
    CROSS JOIN (SELECT @history_row_num := 0, @prev_post_history := NULL) AS init
    WHERE ph.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
),
UserBadges AS (
    SELECT b.UserId,
           GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames,
           COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT rp.PostId,
       rp.Title,
       rp.Score,
       rp.ViewCount,
       rp.Rank,
       rp.CommentCount,
       COALESCE(up.BadgeNames, 'No Badges') AS UserBadges,
       COALESCE(up.BadgeCount, 0) AS TotalBadges,
       ph.PostHistoryTypeId AS RecentHistoryTypeId,
       ph.CreationDate AS RecentHistoryDate
FROM RankedPosts rp
LEFT JOIN RecentPostHistory ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
LEFT JOIN Users u ON rp.PostId = u.Id
LEFT JOIN UserBadges up ON u.Id = up.UserId
WHERE rp.Rank <= 10
  AND (CASE WHEN rp.CommentCount > 5 THEN TRUE ELSE FALSE END) 
ORDER BY rp.Score DESC, rp.ViewCount DESC;
