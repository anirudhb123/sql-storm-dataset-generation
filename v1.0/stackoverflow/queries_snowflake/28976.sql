
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
        LISTAGG(p.Tags, ', ') WITHIN GROUP (ORDER BY p.Id) AS TagsList,
        SIZE(SPLIT(p.Tags, '>')) AS TagCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
)

SELECT 
    pt.Name AS PostType,
    COUNT(rp.PostId) AS TotalPosts,
    AVG(rp.ViewCount) AS AvgViewCount,
    AVG(rp.Score) AS AvgScore,
    SUM(rp.TagCount) AS TotalTags,
    STRING_AGG(rp.Title, '; ') AS Titles,
    MAX(rp.CreationDate) AS MostRecentPostDate
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
WHERE 
    rp.RankByScore <= 5 OR rp.RankByViews <= 5
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC, AvgScore DESC;
