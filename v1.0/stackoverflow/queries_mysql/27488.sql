
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR 
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
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(p.Score, 0)) AS TotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON FIND_IN_SET(t.Id, REPLACE(p.Tags, '><', ',')) > 0
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
         SUBSTRING_INDEX(SUBSTRING_INDEX(trp.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
         TopRankedPosts trp
     INNER JOIN 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
          UNION ALL SELECT 10) numbers ON CHAR_LENGTH(trp.Tags) - CHAR_LENGTH(REPLACE(trp.Tags, '><', '')) >= numbers.n - 1) AS pTags ON trp.PostId = pTags.PostId
JOIN 
    PopularTags ptStats ON pTags.TagName = ptStats.TagName
ORDER BY 
    ptStats.PopularityRank, trp.Score DESC;
