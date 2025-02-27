WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, u.DisplayName AS OwnerName, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpVotes,
           SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, u.DisplayName, p.CreationDate
),
TopPosts AS (
    SELECT Id, Title, CreationDate, OwnerName, 
           CommentCount, UpVotes, DownVotes
    FROM RankedPosts
    WHERE rn = 1
    ORDER BY UpVotes DESC, CommentCount DESC
    LIMIT 10
)
SELECT tp.Title, tp.OwnerName, tp.CommentCount,
       tp.UpVotes, tp.DownVotes, tp.CreationDate,
       COALESCE(ph.Name, 'No History') AS LastPostHistoryType
FROM TopPosts tp
LEFT JOIN PostHistory ph ON tp.Id = ph.PostId
WHERE ph.CreationDate = (
    SELECT MAX(CreationDate)
    FROM PostHistory
    WHERE PostId = tp.Id
)
ORDER BY tp.CreationDate DESC;
