WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN Tags t ON pt.TagId = t.Id
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        rp.Tags
    FROM RankedPosts rp
    WHERE rp.PostRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    ARRAY_TO_STRING(tp.Tags, ', ') AS TagList
FROM TopPosts tp
ORDER BY tp.Score DESC, tp.ViewCount DESC
LIMIT 10;
