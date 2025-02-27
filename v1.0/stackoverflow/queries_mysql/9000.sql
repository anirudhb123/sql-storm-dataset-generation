
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1)) AS tag
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '<>', '')) + 1) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH)
    GROUP BY
        p.Id, u.DisplayName, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT
        PostId, Title, Score, ViewCount, OwnerDisplayName, CommentCount, Tags
    FROM
        RankedPosts
    WHERE
        Rank <= 10
)
SELECT
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Tags,
    ph.CreationDate AS LastEditDate,
    ph.UserDisplayName AS LastEditor
FROM
    TopPosts tp
LEFT JOIN
    PostHistory ph ON tp.PostId = ph.PostId
WHERE
    ph.PostHistoryTypeId IN (4, 5) 
ORDER BY
    tp.Score DESC, tp.ViewCount DESC;
