
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.CommentCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views'
        WHEN rp.ViewCount > 100 THEN 'High View Count'
        ELSE 'Moderate View Count'
    END AS ViewStatus,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date = (SELECT MAX(b2.Date) FROM Badges b2 WHERE b2.UserId = u.Id)
LEFT JOIN 
    (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
        INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON p.Id = rp.PostId
WHERE 
    rp.Rank <= 5
    AND (rp.Score > 10 OR rp.ViewCount IS NOT NULL)
GROUP BY 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.CommentCount,
    b.Name
ORDER BY 
    rp.CreationDate DESC;
