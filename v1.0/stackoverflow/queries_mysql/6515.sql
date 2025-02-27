
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           u.DisplayName AS OwnerDisplayName,
           p.Score,
           p.ViewCount,
           p.AnswerCount,
           p.CommentCount,
           p.FavoriteCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR
), PopularTags AS (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
           COUNT(*) AS TagCount
    FROM Posts
    JOIN (SELECT a.N FROM (SELECT 1 AS N UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
                             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS a
          ) n
    WHERE Tags IS NOT NULL
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 10
), UserReputation AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1
                    WHEN v.VoteTypeId = 3 THEN -1
                    ELSE 0 END) AS ReputationChange
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
), RecentActivity AS (
    SELECT u.DisplayName,
           COUNT(c.Id) AS CommentCount,
           COUNT(b.Id) AS BadgeCount,
           COUNT(ph.Id) AS PostHistoryCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostHistory ph ON u.Id = ph.UserId
    WHERE u.CreationDate > NOW() - INTERVAL 6 MONTH
    GROUP BY u.DisplayName
), CombinedResults AS (
    SELECT rp.PostId,
           rp.Title,
           rp.CreationDate,
           rp.OwnerDisplayName,
           rp.Score,
           rp.ViewCount,
           rp.AnswerCount,
           rp.CommentCount,
           rp.FavoriteCount,
           pt.TagName,
           ra.DisplayName AS ActiveUser,
           ra.CommentCount AS UserComments,
           ra.BadgeCount AS UserBadges,
           ra.PostHistoryCount AS UserPostHistory
    FROM RankedPosts rp
    LEFT JOIN PopularTags pt ON true
    LEFT JOIN RecentActivity ra ON true
)
SELECT *
FROM CombinedResults
WHERE UserComments > 5
AND Score > 10
ORDER BY Score DESC, CreationDate DESC;
