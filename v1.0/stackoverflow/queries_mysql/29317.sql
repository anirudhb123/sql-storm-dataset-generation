
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
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_id
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                       SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                       SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_id ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_id
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
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
