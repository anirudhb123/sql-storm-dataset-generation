
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
KeywordStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount,
        SUM(CHAR_LENGTH(p.Body) - CHAR_LENGTH(REPLACE(p.Body, ' ', '')) + 1) AS WordCount, 
        SUM(CASE WHEN p.Body LIKE '%interesting%' THEN 1 ELSE 0 END) AS InterestingCount 
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName
         FROM 
         (SELECT @row := @row + 1 AS n
          FROM 
           (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) 
           numbers,
           (SELECT @row := 0) r) numbers 
         WHERE n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) + 1) AS t 
        ON p.Id = t.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    us.DisplayName AS OwnerDisplayName,
    ks.UniqueTagCount,
    ks.WordCount,
    ks.InterestingCount
FROM 
    RankedPosts rp
JOIN 
    Users us ON rp.OwnerUserId = us.Id
JOIN 
    KeywordStatistics ks ON rp.PostId = ks.PostId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
