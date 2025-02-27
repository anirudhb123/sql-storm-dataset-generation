WITH TagCounts AS (
    SELECT
        Tags.TagName,
        COUNT(Tags.Id) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags
    JOIN
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '::int'))::int[]
    WHERE
        Posts.PostTypeId = 1
    GROUP BY
        Tags.TagName
), UserActivity AS (
    SELECT
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS PostsCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN
        Votes ON Posts.Id = Votes.PostId
    GROUP BY
        Users.Id, Users.DisplayName
), TopTags AS (
    SELECT
        TagCounts.TagName,
        TagCounts.QuestionCount,
        TagCounts.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY TagCounts.QuestionCount DESC) AS Rank
    FROM
        TagCounts
)
SELECT
    U.DisplayName AS UserName,
    U.PostsCount AS TotalPosts,
    U.AnswersCount,
    U.UpVotesCount,
    T.TagName,
    T.QuestionCount,
    T.AnswerCount
FROM
    UserActivity U
JOIN
    TopTags T ON T.Rank <= 10
WHERE
    U.AnswersCount > 0
ORDER BY
    U.UpVotesCount DESC, U.PostsCount DESC;
