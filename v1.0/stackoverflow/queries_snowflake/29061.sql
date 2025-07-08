
WITH PostTagArray AS (
    SELECT 
        P.Id AS PostId,
        VALUE AS Tag
    FROM 
        Posts P,
        FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags)-2), '><')) AS Tag
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
    LIMIT 10
),
QuestionTitles AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        ARRAY_AGG(DISTINCT T.Tag) AS RelatedTags
    FROM 
        Posts P
    JOIN 
        PostTagArray T ON P.Id = T.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    Q.QuestionId,
    Q.Title,
    Q.RelatedTags,
    T.TagCount AS TagPopularity
FROM 
    QuestionTitles Q
JOIN 
    TopTags T ON T.Tag = ANY(Q.RelatedTags)
ORDER BY 
    TagPopularity DESC, 
    Q.Title ASC;
