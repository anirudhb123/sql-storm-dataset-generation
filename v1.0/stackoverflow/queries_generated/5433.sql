WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           u.DisplayName AS OwnerName,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpVotes,
           SUM(v.VoteTypeId = 3) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
TopPosts AS (
    SELECT PostId, Title, CreationDate, Score, OwnerName, CommentCount, UpVotes, DownVotes
    FROM RankedPosts
    WHERE Rank <= 10
),
PostHistories AS (
    SELECT ph.PostId,
           ph.CreationDate AS HistoryDate,
           pht.Name AS HistoryType,
           ph.Comment,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
)

SELECT tp.PostId,
       tp.Title,
       tp.OwnerName,
       tp.CreationDate,
       tp.Score,
       tp.CommentCount,
       tp.UpVotes,
       tp.DownVotes,
       ph.HistoryDate,
       ph.HistoryType,
       ph.Comment
FROM TopPosts tp
LEFT JOIN PostHistories ph ON tp.PostId = ph.PostId AND ph.HistoryRank <= 3
ORDER BY tp.Score DESC, tp.CreationDate DESC;
