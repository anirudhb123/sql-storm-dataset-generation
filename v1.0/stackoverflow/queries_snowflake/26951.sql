
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
),
TagStatistics AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AverageViews
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(Tags, '>')) AS TagSplit
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(value)
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalScore,
        AverageViews,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10 
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalScore,
    tp.AverageViews,
    rp.OwnerDisplayName,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViewCount
FROM 
    TopTags tp
JOIN 
    RankedPosts rp ON tp.Tag IN (SELECT TRIM(value) FROM LATERAL FLATTEN(INPUT => SPLIT(rp.Tags, '>')))
WHERE 
    rp.RankByScore = 1 
ORDER BY 
    tp.TagRank;
