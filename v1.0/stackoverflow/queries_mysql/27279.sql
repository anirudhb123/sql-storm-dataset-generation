
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.LastActivityDate, 
        p.ViewCount, 
        p.Score, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01' 
        AND p.Score > 0 
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS Tag
    FROM 
        RankedPosts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
),
TagStats AS (
    SELECT 
        Tag, 
        COUNT(*) AS QuestionCount, 
        SUM(Score) AS TotalScore
    FROM 
        PopularTags pt
    JOIN 
        RankedPosts rp ON FIND_IN_SET(pt.Tag, rp.Tags)
    GROUP BY 
        Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    ts.Tag,
    ts.QuestionCount,
    ts.TotalScore
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON FIND_IN_SET(ts.Tag, rp.Tags)
WHERE 
    rp.TagRank <= 3 
ORDER BY 
    ts.TotalScore DESC, 
    rp.ViewCount DESC;
