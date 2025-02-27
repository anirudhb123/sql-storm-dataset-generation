
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
),
TopTags AS (
    SELECT 
        value AS Tag
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, '><')
    WHERE 
        Rank = 1
)
SELECT 
    rt.Tag,
    COUNT(*) AS TotalTopPosts,
    AVG(rp.ViewCount) AS AvgViews,
    AVG(rp.Score) AS AvgScore,
    STRING_AGG(DISTINCT rp.OwnerDisplayName, ',') AS UniqueAuthors
FROM 
    RankedPosts rp
JOIN 
    TopTags rt ON rt.Tag IN (SELECT value FROM STRING_SPLIT(rp.Tags, '><'))
GROUP BY 
    rt.Tag
ORDER BY 
    TotalTopPosts DESC,
    AvgScore DESC;
