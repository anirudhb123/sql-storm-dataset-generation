
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
        AND p.CreationDate > NOW() - INTERVAL 1 YEAR
),
TagStatistics AS (
    SELECT 
        tag AS Tag,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AverageViews
    FROM (
        SELECT 
            p.Score,
            p.ViewCount,
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS tag
        FROM 
            Posts p
        JOIN (
            SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
            SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        WHERE 
            p.PostTypeId = 1
    ) AS TagsTable
    GROUP BY 
        tag
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
    RankedPosts rp ON FIND_IN_SET(tp.Tag, rp.Tags)
WHERE 
    rp.RankByScore = 1 
ORDER BY 
    tp.TagRank;
