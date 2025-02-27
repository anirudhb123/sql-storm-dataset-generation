WITH RankedPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, 
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT r.*, u.DisplayName AS OwnerDisplayName
    FROM RankedPosts r
    JOIN Users u ON r.OwnerUserId = u.Id
    WHERE r.UserRank <= 5
)
SELECT t.PostId, t.Title, t.CreationDate, t.Score, t.CommentCount,
       t.UpVotes, t.DownVotes, t.OwnerDisplayName
FROM TopPosts t
ORDER BY t.Score DESC, t.CommentCount DESC;
