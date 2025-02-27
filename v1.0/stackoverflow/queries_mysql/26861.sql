
WITH TagUsage AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM TagUsage, (SELECT @rank := 0) r
    WHERE PostCount > 5 
    ORDER BY PostCount DESC
),
UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PopularUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        CommentCount,
        Upvotes,
        Downvotes,
        @rank2 := @rank2 + 1 AS Rank
    FROM UserActivity, (SELECT @rank2 := 0) r2
    WHERE QuestionCount > 10
)
SELECT
    TU.TagName,
    TU.PostCount,
    PU.DisplayName AS TopUser,
    PU.QuestionCount,
    PU.CommentCount,
    PU.Upvotes,
    PU.Downvotes
FROM TopTags TU
JOIN PopularUsers PU ON PU.QuestionCount > (SELECT AVG(QuestionCount) FROM PopularUsers)
ORDER BY TU.PostCount DESC, PU.QuestionCount DESC;
