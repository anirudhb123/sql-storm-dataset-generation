WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           p.Tags,
           p.CreationDate,
           u.DisplayName AS OwnerDisplayName,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1
                            WHEN v.VoteTypeId = 3 THEN -1 
                            ELSE 0 END), 0) AS Score,
           COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 -- Only Questions
    GROUP BY p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT rp.*
    FROM RankedPosts rp
    WHERE rp.RN = 1 -- Only the most recent post for each user
),
UserBadgeCounts AS (
    SELECT b.UserId,
           COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT fp.PostId,
       fp.Title,
       fp.Body,
       fp.Tags,
       fp.CreationDate,
       fp.OwnerDisplayName,
       fp.Score,
       fp.CommentCount,
       COALESCE(ubc.BadgeCount, 0) AS BadgeCount
FROM FilteredPosts fp
LEFT JOIN UserBadgeCounts ubc ON fp.OwnerUserId = ubc.UserId
ORDER BY fp.Score DESC, fp.CommentCount DESC, fp.CreationDate DESC
LIMIT 10;
