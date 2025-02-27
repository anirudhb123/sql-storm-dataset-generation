
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews,
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) + 1 AS TagCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
)

SELECT 
    pt.Name AS PostType,
    COUNT(rp.PostId) AS TotalPosts,
    AVG(rp.ViewCount) AS AvgViewCount,
    AVG(rp.Score) AS AvgScore,
    SUM(rp.TagCount) AS TotalTags,
    GROUP_CONCAT(rp.Title SEPARATOR '; ') AS Titles,
    MAX(rp.CreationDate) AS MostRecentPostDate
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
WHERE 
    rp.RankByScore <= 5 OR rp.RankByViews <= 5
GROUP BY 
    pt.Name, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.Tags, rp.TagCount
ORDER BY 
    TotalPosts DESC, AvgScore DESC;
