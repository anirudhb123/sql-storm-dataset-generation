
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 6 MONTH 
        AND p.PostTypeId = 1 
),
TaggedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.RankScore
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Title, ' ', n.n), ' ', -1) AS TagName
         FROM 
            RankedPosts rp
         JOIN 
            (SELECT a.N + b.N * 10 + 1 n 
             FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a, 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b 
             ) n
         ) n
    WHERE 
        LENGTH(rp.Title) - LENGTH(REPLACE(rp.Title, ' ', '')) >= n.n - 1
    GROUP BY rp.Id) t 
    GROUP BY 
        rp.Id, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount, rp.RankScore
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Tags
FROM 
    TaggedPosts tp
WHERE 
    tp.RankScore <= 10
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
