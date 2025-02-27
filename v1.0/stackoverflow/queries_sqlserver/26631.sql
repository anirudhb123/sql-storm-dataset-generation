
WITH BasePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS TagsArray,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagPerformance AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS QuestionCount,
        AVG(bp.Score) AS AverageScore,
        AVG(u.Reputation) AS AverageOwnerReputation
    FROM 
        BasePosts bp
    CROSS APPLY STRING_SPLIT(SUBSTRING(bp.Tags, 2, LEN(bp.Tags) - 2), '>') 
    JOIN 
        Users u ON bp.OwnerDisplayName = u.DisplayName
    GROUP BY 
        value
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
    BasePosts p ON tt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>'))
WHERE 
    tt.TagRank <= 5
ORDER BY 
    tt.TagRank, p.CreationDate DESC;
