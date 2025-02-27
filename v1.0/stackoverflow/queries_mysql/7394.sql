
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COUNT(v.Id) AS VoteCount,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
     FROM 
     (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
      SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_name ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_name.TagName
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
