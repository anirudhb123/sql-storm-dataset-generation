
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL 30 DAY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    COUNT(c.Id) AS CommentCount,
    MIN(ph.CreationDate) AS FirstHistoryDate,
    MAX(ph.CreationDate) AS LastHistoryDate
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.Author
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
