
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
           u.DisplayName AS OwnerDisplayName, 
           COUNT(c.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
           STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN STRING_SPLIT(p.Tags, ',') AS tag_names ON 1=1
    LEFT JOIN Tags t ON t.TagName = tag_names.value
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME2) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT * FROM RankedPosts WHERE Rank <= 10
)
SELECT tp.Id, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
       tp.OwnerDisplayName, tp.CommentCount, 
       tp.UpVoteCount, tp.DownVoteCount, 
       tp.Tags
FROM TopPosts tp
ORDER BY tp.Score DESC, tp.ViewCount DESC;
