
WITH TagStatistics AS (
    SELECT
        LTRIM(RTRIM(value)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    GROUP BY
        LTRIM(RTRIM(value))
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
            LTRIM(RTRIM(value))
        FROM
            Posts P
        CROSS APPLY STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><')
        WHERE
            P.OwnerUserId = U.Id
    )
ORDER BY
    U.Reputation DESC, T.PostCount DESC;
