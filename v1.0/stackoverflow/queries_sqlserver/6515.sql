
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
    WHERE p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
), PopularTags AS (
    SELECT value AS TagName,
           COUNT(*) AS TagCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE Tags IS NOT NULL
    GROUP BY value
    ORDER BY TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    WHERE u.CreationDate > DATEADD(month, -6, '2024-10-01 12:34:56')
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
    LEFT JOIN PopularTags pt ON 1 = 1
    LEFT JOIN RecentActivity ra ON 1 = 1
)
SELECT *
FROM CombinedResults
WHERE UserComments > 5
AND Score > 10
ORDER BY Score DESC, CreationDate DESC;
