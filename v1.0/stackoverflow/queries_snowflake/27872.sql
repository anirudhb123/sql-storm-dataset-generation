
WITH QuestionTags AS (
    SELECT
        Posts.Id AS QuestionId,
        Posts.Title AS QuestionTitle,
        Posts.CreationDate AS QuestionCreationDate,
        Posts.Tags,
        Tag
    FROM
        Posts,
        LATERAL SPLIT_TO_TABLE(SUBSTR(Posts.Tags, 2, LENGTH(Posts.Tags) - 2), '><') AS Tag
    WHERE
        Posts.PostTypeId = 1
),
TagStatistics AS (
    SELECT
        Tag,
        COUNT(*) AS TagCount,
        MIN(QuestionCreationDate) AS FirstUsed,
        MAX(QuestionCreationDate) AS MostRecentUsed
    FROM
        QuestionTags
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        TagCount,
        FirstUsed,
        MostRecentUsed,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM
        TagStatistics
    WHERE
        TagCount > 5  
)

SELECT
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    TT.Tag,
    TT.TagCount,
    TT.FirstUsed,
    TT.MostRecentUsed
FROM
    Users U
JOIN
    Posts P ON U.Id = P.OwnerUserId
JOIN
    TopTags TT ON TT.Tag = ANY(SPLIT_TO_ARRAY(SUBSTR(P.Tags, 2, LENGTH(P.Tags) - 2), '><'))
WHERE
    P.PostTypeId = 1  
ORDER BY
    TT.TagCount DESC,
    U.Reputation DESC
LIMIT 10;
