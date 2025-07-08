
WITH TagCounts AS (
    SELECT
        TRIM(value) AS Tag,
        COUNT(*) AS PostCount
    FROM (
        SELECT
            SPLIT(REPLACE(SUBSTR(Tags, 2, LEN(Tags) - 2), '><', '||'), '||') AS value
        FROM
            Posts
        WHERE
            PostTypeId = 1  
    )
    GROUP BY
        TRIM(value)
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagCounts
    WHERE
        PostCount > 1  
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
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC, CommentCount DESC) AS Rank
    FROM
        UserEngagement 
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
                    TRIM(value)
                FROM
                    LATERAL SPLIT(REPLACE(SUBSTR(P.Tags, 2, LEN(P.Tags) - 2), '><', '||'), '||') AS value
                WHERE
                    P.OwnerUserId IS NOT NULL AND P.PostTypeId = 1 
            )
    )
WHERE
    T.Rank <= 10  
ORDER BY
    T.PostCount DESC,
    U.QuestionCount DESC;
