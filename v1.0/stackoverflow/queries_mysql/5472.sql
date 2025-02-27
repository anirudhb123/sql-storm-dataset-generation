
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
           u.DisplayName AS OwnerDisplayName, 
           COUNT(c.Id) AS CommentCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
           GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag
               FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                     UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
               WHERE CHAR_LENGTH(p.Tags) 
                     -CHAR_LENGTH(REPLACE(p.Tags, ',', ''))>=numbers.n-1) AS tag_names ON true
    LEFT JOIN Tags t ON t.TagName = tag_names.tag
    WHERE p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT * FROM RankedPosts WHERE Rank <= 10
)
SELECT tp.Id, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
       tp.OwnerDisplayName, tp.CommentCount, 
       tp.UpVoteCount, tp.DownVoteCount, 
       GROUP_CONCAT(DISTINCT tag) AS Tags
FROM TopPosts tp
JOIN (SELECT DISTINCT tag FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, ',', numbers.n), ',', -1)) AS tag
                                FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                                      UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                                WHERE CHAR_LENGTH(tp.Tags) 
                                      -CHAR_LENGTH(REPLACE(tp.Tags, ',', ''))>=numbers.n-1) AS t) ON true
GROUP BY tp.Id, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
         tp.OwnerDisplayName, tp.CommentCount, 
         tp.UpVoteCount, tp.DownVoteCount
ORDER BY tp.Score DESC, tp.ViewCount DESC;
