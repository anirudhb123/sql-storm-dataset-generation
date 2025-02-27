
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS tag
    LEFT JOIN Tags t ON t.TagName = tag.value
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, pt.Name
),
TopPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.Rank, rp.ViewCount DESC) AS OverallRank
    FROM RankedPosts rp
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
