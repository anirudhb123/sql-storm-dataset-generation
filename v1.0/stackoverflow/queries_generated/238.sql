WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName AS OwnerDisplayName,
           COUNT(c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName
),
PostStats AS (
    SELECT rp.*, 
           (UpVotes - DownVotes) AS NetVotes,
           RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS VoteRank
    FROM RecentPosts rp
),
TopPosts AS (
    SELECT * FROM PostStats WHERE VoteRank <= 10
)
SELECT tp.*, 
       CASE 
           WHEN tp.CommentCount = 0 THEN 'No Comments'
           WHEN tp.CommentCount > 0 AND tp.CommentCount <= 5 THEN 'Few Comments'
           ELSE 'Many Comments'
       END AS CommentStatus,
       COALESCE(pt.Name, 'N/A') AS PostTypeName,
       COALESCE(b.AdCount, 0) AS BadgeCount
FROM TopPosts tp
LEFT JOIN PostTypes pt ON tp.Id IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
LEFT JOIN (SELECT UserId, COUNT(*) AS AdCount 
            FROM Badges 
            GROUP BY UserId) b ON b.UserId = tp.OwnerDisplayName
ORDER BY tp.NetVotes DESC, tp.ViewCount DESC;
