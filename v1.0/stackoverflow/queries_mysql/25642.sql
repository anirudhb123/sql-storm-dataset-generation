
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
                    (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
               ORDER BY n) n
         WHERE 
         n.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1)
        ) AS tagArray ON true
    JOIN 
        Tags t ON t.TagName = tagArray.Tag
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, pt.Name
),

TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.ViewCount, 
        rp.Score, 
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    u.Location AS OwnerLocation
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.Score DESC;
