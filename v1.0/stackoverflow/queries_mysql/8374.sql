
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_name = pt.Name, @row_number + 1, 1) AS Rank,
        @prev_name := pt.Name,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    CROSS JOIN (
        SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
        FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers 
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS tags_list
    LEFT JOIN Tags t ON t.TagName = tags_list.tag
    CROSS JOIN (SELECT @row_number := 0, @prev_name := '') AS init
    WHERE p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, pt.Name
),
TopPosts AS (
    SELECT 
        rp.*,
        @overall_rank := @overall_rank + 1 AS OverallRank
    FROM RankedPosts rp
    CROSS JOIN (SELECT @overall_rank := 0) AS init
    ORDER BY rp.Rank, rp.ViewCount DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.VoteCount,
    tp.Tags,
    tp.OverallRank
FROM TopPosts tp
WHERE tp.OverallRank <= 10
ORDER BY tp.OverallRank;
