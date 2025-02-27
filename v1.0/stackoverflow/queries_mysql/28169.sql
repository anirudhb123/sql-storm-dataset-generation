
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
),
KeywordCounts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rg.value AS Keyword,
        COUNT(*) AS KeywordCount
    FROM 
        RankedPosts rp,
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Body, ' ', n.n), ' ', -1)) AS value
         FROM RankedPosts rp 
         JOIN (SELECT a.N + b.N * 10 + 1 AS n
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                     SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
                     SELECT 8 UNION ALL SELECT 9) a,
                    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                     SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
                     SELECT 8 UNION ALL SELECT 9) b 
               ) n 
         WHERE n.n <= 1 + LENGTH(rp.Body) - LENGTH(REPLACE(rp.Body, ' ', '')) ) AS rg
    WHERE 
        rg.value NOT IN ('the', 'is', 'at', 'which', 'on', 'for', 'by', 'to', 'and', 'a', 'an') 
    GROUP BY 
        rp.PostId, rp.Title, rg.value
),
TopKeywords AS (
    SELECT 
        PostId,
        Keyword,
        KeywordCount,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY KeywordCount DESC) AS KeywordRank
    FROM 
        KeywordCounts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.CreationDate,
    GROUP_CONCAT(CONCAT(kw.Keyword, ': ', kw.KeywordCount) SEPARATOR ', ') AS TopKeywords
FROM 
    RankedPosts rp
LEFT JOIN 
    TopKeywords kw ON rp.PostId = kw.PostId AND kw.KeywordRank <= 3 
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.CreationDate
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;
