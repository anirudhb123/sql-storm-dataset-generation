
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(LENGTH(p.Body), 0), 1) AS BodyLength
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 100 
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS QuestionCount,
        SUM(BodyLength) AS TotalBodyLength,
        AVG(BodyLength) AS AvgBodyLength
    FROM 
        RankedPosts
    JOIN 
    (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        rn = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalBodyLength,
        AvgBodyLength,
        RANK() OVER (ORDER BY QuestionCount DESC) AS TagRank
    FROM 
        TagStatistics
)

SELECT 
    t.TagName,
    t.QuestionCount,
    t.TotalBodyLength,
    t.AvgBodyLength,
    COALESCE(ROUND(CAST(t.TotalBodyLength AS DECIMAL) / NULLIF(t.QuestionCount, 0), 2), 0) AS AvgBodyLengthPerQuestion
FROM 
    TopTags t
WHERE 
    t.TagRank <= 5 
ORDER BY 
    t.TagRank;
