WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 -- Only Questions
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.CommentCount DESC) AS PostRank
    FROM RankedPosts rp
    WHERE rp.rn = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM TopPosts tp
LEFT JOIN Posts p ON tp.PostId = p.Id
LEFT JOIN STRING_TO_ARRAY(p.Tags, ',') AS tagIds ON TRUE
LEFT JOIN Tags t ON t.Id = tagIds::int
WHERE tp.PostRank <= 10
GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName, tp.CommentCount
ORDER BY tp.PostRank;
