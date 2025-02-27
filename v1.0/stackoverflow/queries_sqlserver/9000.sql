
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.CreationDate -- Added to GROUP BY
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_SPLIT(p.Tags, '<>') AS tag ON tag.value IS NOT NULL -- Replaced UNNEST and STRING_TO_ARRAY
    LEFT JOIN 
        Tags t ON t.TagName = tag.value -- Use tag.value to fetch the tag name
    WHERE
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 MONTH')
    GROUP BY
        p.Id, u.DisplayName, p.Title, p.Score, p.ViewCount, p.PostTypeId, p.CreationDate -- Added p.CreationDate to GROUP BY
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
