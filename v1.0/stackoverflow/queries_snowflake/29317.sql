
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL SPLIT_TO_TABLE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_id ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_id.value
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName, p.ViewCount
),

TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.Author,
    tp.ViewCount,
    tp.CommentCount,
    tp.Tags,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(ph_sub.CreationDate) 
        FROM PostHistory ph_sub
        WHERE ph_sub.PostId = tp.PostId AND ph_sub.PostHistoryTypeId IN (4, 5)  
    )
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
