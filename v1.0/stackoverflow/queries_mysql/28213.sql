
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY GROUP_CONCAT(tag.TagName ORDER BY tag.TagName) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
         FROM Posts p 
         JOIN (SELECT @row := @row + 1 AS n FROM 
               (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
                SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers, 
                (SELECT @row := 0) r
               ) n) AS n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag ON FIND_IN_SET(tag.TagName, TRIM(BOTH '<' AND '>' FROM p.Tags))
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY) 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        Score,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS OverallRank
    FROM 
        RankedPosts
    WHERE 
        Rank = 1 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score
FROM 
    TopPosts tp
JOIN 
    (SELECT 
        COUNT(*) AS TotalQuestions,
        AVG(ViewCount) AS AvgViewCount
     FROM 
        RankedPosts) stats ON TRUE
ORDER BY 
    tp.OverallRank
LIMIT 10;
