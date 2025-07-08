
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TagStatistics AS (
    SELECT 
        TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM VALUE)) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')) AS VALUE
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10 
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalViews,
    tp.TotalScore,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName
FROM 
    TopTags tp
JOIN 
    RankedPosts rp ON POSITION(tp.Tag IN rp.Tags) > 0
WHERE 
    rp.Rank <= 5 
ORDER BY 
    tp.Rank, rp.Score DESC;
