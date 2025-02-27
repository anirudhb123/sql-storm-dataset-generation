
WITH PostTagArray AS (
    SELECT 
        P.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts P
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
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
        GROUP_CONCAT(DISTINCT T.Tag) AS RelatedTags
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
    TopTags T ON FIND_IN_SET(T.Tag, Q.RelatedTags)
ORDER BY 
    TagPopularity DESC, 
    Q.Title ASC;
