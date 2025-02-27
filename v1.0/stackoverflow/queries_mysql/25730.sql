
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 
            a.N + b.N * 10 + 1 n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON U.Id = C.UserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM
        TagCounts, (SELECT @rank := 0) r
    ORDER BY
        PostCount DESC
)
SELECT
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.QuestionsAsked,
    U.CommentsMade,
    U.UpvotesReceived,
    U.DownvotesReceived,
    T.Tag,
    T.PostCount
FROM
    UserReputation U
JOIN
    TopTags T ON U.Reputation >= 1000  
WHERE
    T.Rank <= 5  
ORDER BY
    U.Reputation DESC, T.PostCount DESC;
