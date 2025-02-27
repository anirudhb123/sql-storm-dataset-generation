
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (NOW() - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    u.DisplayName AS Author,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.num), ',', -1)) AS tag
     FROM 
         (SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers
     JOIN 
         Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.num - 1
    ) AS tag ON tag.tag IS NOT NULL
LEFT JOIN 
    Tags t ON tag.tag = t.TagName
GROUP BY 
    u.DisplayName, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.CommentCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
