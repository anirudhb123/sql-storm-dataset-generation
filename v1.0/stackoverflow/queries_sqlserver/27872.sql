
WITH QuestionTags AS (
    SELECT
        Posts.Id AS QuestionId,
        Posts.Title AS QuestionTitle,
        Posts.CreationDate AS QuestionCreationDate,
        Posts.Tags,
        value AS Tag
    FROM
        Posts
    CROSS APPLY (
        SELECT value 
        FROM STRING_SPLIT(SUBSTRING(Posts.Tags, 2, LEN(Posts.Tags)-2), '><')
    ) AS SplitTags
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
    TopTags TT ON TT.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags)-2), '><'))
WHERE
    P.PostTypeId = 1  
ORDER BY
    TT.TagCount DESC,
    U.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
