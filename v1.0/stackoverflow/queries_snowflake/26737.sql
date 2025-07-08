
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
        p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp)
)

SELECT
    rp.OwnerDisplayName,
    COUNT(rp.PostId) AS TotalPosts,
    SUM(CASE WHEN rp.RankByViews = 1 THEN 1 ELSE 0 END) AS TopViewPostCount,
    SUM(CASE WHEN rp.RankByScore = 1 THEN 1 ELSE 0 END) AS TopScorePostCount,
    ARRAY_AGG(rp.Title) AS PostTitles,
    LISTAGG(DISTINCT tag.TagName, ', ') AS TagsUsed
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
        p.Id, 
        TRIM(value) AS TagName
     FROM 
        Posts p,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '> <')))) tag ON rp.PostId = tag.Id
GROUP BY 
    rp.OwnerDisplayName
ORDER BY 
    TotalPosts DESC, TopViewPostCount DESC, TopScorePostCount DESC
LIMIT 10;
