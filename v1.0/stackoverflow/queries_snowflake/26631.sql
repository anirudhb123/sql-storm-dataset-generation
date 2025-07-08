
WITH BasePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><') AS TagsArray,
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
        Tag,
        COUNT(*) AS QuestionCount,
        AVG(Score) AS AverageScore,
        AVG(OwnerReputation) AS AverageOwnerReputation
    FROM 
        BasePosts,
        LATERAL FLATTEN(input => TagsArray) AS Tag
    JOIN 
        Users u ON BasePosts.OwnerDisplayName = u.DisplayName
    GROUP BY 
        Tag
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
    BasePosts p ON tt.Tag = ANY(p.TagsArray)
WHERE 
    tt.TagRank <= 5
ORDER BY 
    tt.TagRank, p.CreationDate DESC;
