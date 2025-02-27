
WITH QuestionTags AS (
    SELECT
        Posts.Id AS QuestionId,
        Posts.Title AS QuestionTitle,
        Posts.CreationDate AS QuestionCreationDate,
        Posts.Tags,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '><', n.n), '><', -1) AS Tag
    FROM
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
        UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
        UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) n ON CHAR_LENGTH(Posts.Tags) - CHAR_LENGTH(REPLACE(Posts.Tags, '><', '')) >= n.n - 1
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
    TopTags TT ON FIND_IN_SET(TT.Tag, REPLACE(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><', ',')) > 0
WHERE
    P.PostTypeId = 1  
ORDER BY
    TT.TagCount DESC,
    U.Reputation DESC
LIMIT 10;
