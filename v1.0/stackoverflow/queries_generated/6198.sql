WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.CreationDate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        rp.Rank,
        rp.CreationDate
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    tp.CreationDate,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName 
     JOIN Tags t ON t.TagName = tagName 
     WHERE p.Id = tp.PostId) AS Tags
FROM TopPosts tp
ORDER BY tp.Score DESC, tp.ViewCount DESC;
