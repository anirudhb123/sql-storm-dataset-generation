
WITH BasePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagsArray,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
TagPerformance AS (
    SELECT 
        TagsArray AS Tag,
        COUNT(*) AS QuestionCount,
        AVG(bp.Score) AS AverageScore,
        AVG(u.Reputation) AS AverageOwnerReputation
    FROM 
        BasePosts bp
    JOIN 
        Users u ON bp.OwnerDisplayName = u.DisplayName
    GROUP BY 
        TagsArray
),
TopTags AS (
    SELECT 
        Tag,
        QuestionCount,
        AverageScore,
        AverageOwnerReputation,
        RANK() OVER (ORDER BY QuestionCount DESC) AS TagRank
    FROM 
        TagPerformance
    WHERE 
        QuestionCount > 10
)
SELECT 
    tt.Tag,
    tt.QuestionCount,
    tt.AverageScore,
    tt.AverageOwnerReputation,
    p.PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.OwnerDisplayName
FROM 
    TopTags tt
JOIN 
    BasePosts p ON FIND_IN_SET(tt.Tag, p.TagsArray)
WHERE 
    tt.TagRank <= 5
ORDER BY 
    tt.TagRank, p.CreationDate DESC;
