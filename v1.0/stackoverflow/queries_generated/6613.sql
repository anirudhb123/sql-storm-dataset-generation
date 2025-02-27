WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.Score, 
           p.ViewCount, 
           p.CreationDate, 
           p.OwnerUserId, 
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) AS VoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
TopPosts AS (
    SELECT rp.Id, rp.Title, rp.Score, rp.ViewCount, rp.CommentCount, rp.VoteCount, pt.Name AS PostType
    FROM RankedPosts rp
    JOIN PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE rp.Rank <= 10
)
SELECT tp.Title, 
       tp.Score, 
       tp.ViewCount,
       tp.CommentCount, 
       tp.VoteCount, 
       u.DisplayName, 
       u.Reputation,
       u.CreationDate
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
WHERE u.Reputation > 1000
ORDER BY tp.Score DESC;
