
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
)

SELECT
    rp.OwnerDisplayName,
    COUNT(rp.PostId) AS TotalPosts,
    SUM(CASE WHEN rp.RankByViews = 1 THEN 1 ELSE 0 END) AS TopViewPostCount,
    SUM(CASE WHEN rp.RankByScore = 1 THEN 1 ELSE 0 END) AS TopScorePostCount,
    GROUP_CONCAT(rp.Title) AS PostTitles,
    GROUP_CONCAT(DISTINCT tag.TagName ORDER BY tag.TagName ASC SEPARATOR ', ') AS TagsUsed
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
        p.Id, 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1)) AS TagName
     FROM 
        Posts p
     INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1) tag ON rp.PostId = tag.Id
GROUP BY 
    rp.OwnerDisplayName
ORDER BY 
    TotalPosts DESC, TopViewPostCount DESC, TopScorePostCount DESC
LIMIT 10;
