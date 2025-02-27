
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts 
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(Tags) 
        -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        TagStats
)
SELECT 
    t.Tag,
    t.PostCount,
    t.TotalViews,
    t.TotalScore,
    t.ViewRank,
    t.ScoreRank,
    (SELECT GROUP_CONCAT(r.OwnerDisplayName SEPARATOR ', ') FROM RankedPosts r WHERE r.Tags LIKE CONCAT('%', t.Tag, '%')) AS TopPostOwners
FROM 
    TopTags t
WHERE 
    t.PostCount > 5 
ORDER BY 
    t.TotalViews DESC, t.TotalScore DESC;
