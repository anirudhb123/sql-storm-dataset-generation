
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) 
        AND p.ViewCount > 100
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.Score, 0)) AS TotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = CAST(value AS INT) WHERE CHARINDEX('<', p.Tags) > 0
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS PopularityRank
    FROM 
        TagStats
    WHERE 
        PostCount > 0
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    pt.Name AS PostType,
    pTags.TagName,
    ptStats.PopularityRank
FROM 
    TopRankedPosts trp
JOIN 
    PostTypes pt ON trp.PostId = pt.Id
JOIN 
    (SELECT 
         trp.PostId, 
         value AS TagName
     FROM 
         TopRankedPosts trp
     CROSS APPLY STRING_SPLIT(trp.Tags, '><')) AS pTags ON trp.PostId = pTags.PostId
JOIN 
    PopularTags ptStats ON pTags.TagName = ptStats.TagName
ORDER BY 
    ptStats.PopularityRank, trp.Score DESC;
