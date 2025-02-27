WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
           COUNT(c.Id) AS CommentCount,
           AVG(v.CreationDate) AS AvgVoteTime
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
TopPosts AS (
    SELECT Id, Title, CreationDate, Score, ViewCount, CommentCount, AvgVoteTime
    FROM RankedPosts
    WHERE Rank <= 5
)
SELECT tp.Id, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount,
       u.DisplayName AS OwnerDisplayName, u.Reputation,
       (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
       (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t
        JOIN Posts p ON t.ExcerptPostId = p.Id
        WHERE p.Id = tp.Id) AS Tags
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
ORDER BY tp.Score DESC, tp.ViewCount DESC;
