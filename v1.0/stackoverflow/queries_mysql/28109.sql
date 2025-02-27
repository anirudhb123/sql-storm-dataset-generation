
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS AuthorName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.AuthorName,
    GROUP_CONCAT(DISTINCT c.Text SEPARATOR ' | ') AS Comments,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    Badges b ON rp.AuthorName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    rp.Rank <= 10
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.Tags, rp.AuthorName
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
