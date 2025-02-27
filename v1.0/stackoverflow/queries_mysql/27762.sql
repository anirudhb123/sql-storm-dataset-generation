
WITH TagStatistics AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Posts
    JOIN
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        ON CHAR_LENGTH(Tags)
           -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY
        TagName
),
UserReputation AS (
    SELECT
        Users.Id,
        Users.DisplayName,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY
        Users.Id, Users.DisplayName, Users.Reputation
),
TopTags AS (
    SELECT
        TagName,
        PostCount
    FROM
        TagStatistics
    ORDER BY
        PostCount DESC
    LIMIT 10
)
SELECT
    U.DisplayName,
    U.Reputation,
    U.PostCount AS TotalPosts,
    U.Questions,
    U.Answers,
    T.TagName,
    T.PostCount AS TagPostCount
FROM
    UserReputation U
JOIN
    TopTags T ON T.TagName IN (
        SELECT
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1))
        FROM
            Posts P
        JOIN
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
            ON CHAR_LENGTH(P.Tags)
               -CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
        WHERE
            P.OwnerUserId = U.Id
    )
ORDER BY
    U.Reputation DESC, T.PostCount DESC;
