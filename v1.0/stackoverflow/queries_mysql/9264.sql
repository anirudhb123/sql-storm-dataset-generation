
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM RankedPosts
    WHERE Rank <= 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    JOIN (SELECT DISTINCT TRIM(BOTH ' ' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
          FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
          WHERE CHAR_LENGTH(p.Tags) -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) as tag
    JOIN Tags t ON t.TagName = tag.tag
    GROUP BY p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    pt.Tags,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM TopPosts tp
LEFT JOIN Comments c ON tp.PostId = c.PostId
LEFT JOIN Votes v ON tp.PostId = v.PostId
LEFT JOIN PostTags pt ON tp.PostId = pt.PostId
GROUP BY tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName, pt.Tags
ORDER BY tp.Score DESC, tp.ViewCount DESC;
