
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    WHERE
        PostTypeId = 1 
    AND
        n.n <= CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagCounts
    WHERE
        PostCount > 5 
),
ActiveUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionsAsked,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(IFNULL(V.BountyAmount, 0)) AS TotalBounty
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE
        U.Reputation > 100 
    GROUP BY
        U.Id, U.DisplayName
),
UserTagRelationships AS (
    SELECT
        U.Id AS UserId,
        T.Tag,
        COUNT(*) AS UserTagCount
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    JOIN
        TagCounts T ON T.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1)
    JOIN
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    WHERE
        P.PostTypeId = 1 
    AND
        n.n <= CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) + 1
    GROUP BY
        U.Id, T.Tag
)
SELECT
    U.DisplayName AS UserName,
    T.Tag,
    U.QuestionsAsked,
    U.PositiveScoredQuestions,
    U.TotalBounty,
    TR.UserTagCount,
    T.PostCount
FROM
    ActiveUsers U
JOIN
    UserTagRelationships TR ON U.UserId = TR.UserId
JOIN
    TopTags T ON TR.Tag = T.Tag
ORDER BY
    U.TotalBounty DESC,
    T.PostCount DESC;
