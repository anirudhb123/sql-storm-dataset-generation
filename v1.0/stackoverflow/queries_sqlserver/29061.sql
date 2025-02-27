
WITH PostTagArray AS (
    SELECT 
        P.Id AS PostId,
        value AS Tag
    FROM 
        Posts P
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS T
    WHERE 
        P.PostTypeId = 1 
),
TagFrequency AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        PostTagArray
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagCount
    FROM 
        TagFrequency
    ORDER BY 
        TagCount DESC
)
SELECT TOP 10
    Q.QuestionId,
    Q.Title,
    STRING_AGG(DISTINCT T.Tag, ',') AS RelatedTags,
    T.TagCount AS TagPopularity
FROM 
    (SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.Tags
     FROM 
        Posts P
     WHERE 
        P.PostTypeId = 1) Q
JOIN 
    PostTagArray T ON Q.QuestionId = T.PostId
GROUP BY 
    Q.QuestionId, Q.Title
ORDER BY 
    TagPopularity DESC, 
    Q.Title ASC;
