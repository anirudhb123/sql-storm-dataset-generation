
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 
),
ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', n.n), '> <', -1) AS TagName
    FROM 
        Posts p
    INNER JOIN 
        (SELECT a.N + b.N * 10 + 1 n 
         FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
         CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
         ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= n.n - 1
    WHERE 
        p.Tags IS NOT NULL
)
SELECT 
    t.TagName,
    COUNT(DISTINCT tp.PostId) AS QuestionCount,
    SUM(tp.ViewCount) AS TotalViews,
    AVG(tp.Score) AS AvgScore,
    GROUP_CONCAT(tp.OwnerDisplayName SEPARATOR ', ') AS PostOwners
FROM 
    ProcessedTags t
JOIN 
    TopPosts tp ON t.PostId = tp.PostId
GROUP BY 
    t.TagName
ORDER BY 
    QuestionCount DESC
LIMIT 10;
