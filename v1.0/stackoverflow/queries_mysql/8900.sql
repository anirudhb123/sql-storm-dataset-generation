
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        rp.Score DESC,
        rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.CommentCount,
    pt.Name AS PostTypeName,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId IN (SELECT PostId FROM Posts WHERE PostTypeId = pt.Id)
LEFT JOIN 
    (SELECT 
         SUBSTRING_INDEX(SUBSTRING_INDEX(pp.Tags, '><', n.n), '><', -1) AS TagName,
         pp.Id AS PostId
     FROM 
         Posts pp
     JOIN 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
     ON CHAR_LENGTH(pp.Tags) - CHAR_LENGTH(REPLACE(pp.Tags, '><', '')) >= n.n - 1) AS t ON t.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.OwnerReputation, tp.CommentCount, pt.Name
ORDER BY 
    tp.Score DESC;
