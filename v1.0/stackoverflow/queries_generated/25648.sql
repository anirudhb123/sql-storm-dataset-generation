WITH TagStatistics AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(Posts.ViewCount) AS AvgViewCount,
        AVG(Posts.Score) AS AvgScore
    FROM
        Tags
    LEFT JOIN
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '>')::int[])
    GROUP BY
        Tags.TagName
),
TopUsers AS (
    SELECT
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(Votes.VoteTypeId = 2) AS UpVotesReceived,
        SUM(Votes.VoteTypeId = 3) AS DownVotesReceived
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN
        Votes ON Posts.Id = Votes.PostId
    GROUP BY
        Users.Id
    ORDER BY
        PostsCreated DESC
    LIMIT 10
),
PopularTags AS (
    SELECT
        TagStatistics.TagName,
        TagStatistics.PostCount,
        TagStatistics.QuestionCount,
        TagStatistics.AnswerCount,
        TagStatistics.AvgViewCount,
        TagStatistics.AvgScore,
        ROW_NUMBER() OVER (ORDER BY TagStatistics.PostCount DESC) AS Rank
    FROM
        TagStatistics
    WHERE
        TagStatistics.PostCount > 10
)
SELECT
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.AvgViewCount,
    t.AvgScore,
    u.UserId AS TopUserId,
    u.DisplayName AS TopUserName
FROM
    PopularTags t
LEFT JOIN 
    TopUsers u ON u.PostsCreated = (
        SELECT MAX(PostsCreated)
        FROM TopUsers
    )
WHERE
    t.Rank <= 5
ORDER BY
    t.PostCount DESC;
