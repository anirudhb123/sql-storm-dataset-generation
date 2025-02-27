WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
           COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS comment_count
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= current_date - INTERVAL '1 year'
),
TopPosts AS (
    SELECT rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.rn, rp.comment_count
    FROM RankedPosts rp
    WHERE rp.rn = 1
),
UserDetails AS (
    SELECT u.Id AS user_id, u.DisplayName, 
           COALESCE(b.Name, 'No Badge') AS badge_name
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1
)
SELECT tp.Title, tp.CreationDate, tp.Score, 
       ud.DisplayName AS UserName, 
       ud.badge_name,
       (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.Id AND v.VoteTypeId = 2) AS upvotes,
       (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.Id AND v.VoteTypeId = 3) AS downvotes
FROM TopPosts tp
JOIN UserDetails ud ON tp.OwnerUserId = ud.user_id
LEFT JOIN PostHistory ph ON ph.PostId = tp.Id AND ph.CreationDate = (
    SELECT MAX(ph2.CreationDate) 
    FROM PostHistory ph2 
    WHERE ph2.PostId = tp.Id AND ph2.PostHistoryTypeId IN (10, 11)
)
WHERE ud.badge_name IS NOT NULL OR tp.comment_count > 5
ORDER BY tp.Score DESC, tp.CreationDate ASC;
