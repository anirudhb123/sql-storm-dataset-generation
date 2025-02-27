
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM
        TagCounts, (SELECT @rank := 0) r
    WHERE
        PostCount > 1  
    ORDER BY PostCount DESC
),
UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        CommentCount,
        VoteCount,
        @userRank := @userRank + 1 AS Rank
    FROM
        UserEngagement, (SELECT @userRank := 0) ur
)
SELECT
    T.Tag,
    T.PostCount,
    U.DisplayName,
    U.QuestionCount,
    U.CommentCount,
    U.VoteCount
FROM
    TopTags T
JOIN
    TopUsers U ON U.UserId IN (
        SELECT
            P.OwnerUserId
        FROM
            Posts P
        WHERE
            P.OwnerUserId IS NOT NULL AND P.PostTypeId = 1 
            AND T.Tag IN (
                SELECT
                    SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1)
                FROM
                    Posts P
                JOIN (
                    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                    SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                    SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
                ) n ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= n.n - 1
                WHERE
                    P.OwnerUserId IS NOT NULL AND P.PostTypeId = 1 
            )
    )
WHERE
    T.Rank <= 10  
ORDER BY
    T.PostCount DESC,
    U.QuestionCount DESC;
