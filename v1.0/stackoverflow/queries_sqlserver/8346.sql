
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank
    FROM 
        RecentPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    STRING_AGG(t.TagName, ', ') AS TagName
FROM 
    TopPosts tp
    JOIN Posts p ON tp.PostId = p.Id
    CROSS APPLY (
        SELECT 
            t.TagName
        FROM 
            STRING_SPLIT(p.Tags, ',') AS tag
            JOIN Tags t ON TRIM(tag.value) = t.TagName
    ) AS t
WHERE 
    tp.Rank <= 10
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.CommentCount, tp.VoteCount, tp.Rank
ORDER BY 
    tp.Rank;
