-- Performance benchmarking query
WITH UserStatistics AS (
    SELECT
        Users.DisplayName,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        SUM(Votes.VoteTypeId = 2) AS UpVotes,
        SUM(Votes.VoteTypeId = 3) AS DownVotes
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Comments ON Users.Id = Comments.UserId
    LEFT JOIN Votes ON Users.Id = Votes.UserId
    GROUP BY Users.Id
),
PostStatistics AS (
    SELECT
        Posts.Id,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        Posts.AnswerCount,
        Posts.CommentCount,
        Tags.TagName
    FROM Posts
    LEFT JOIN Tags ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    WHERE Posts.CreationDate >= '2023-01-01'
)
SELECT
    UserStatistics.DisplayName,
    UserStatistics.Reputation,
    UserStatistics.PostCount,
    UserStatistics.CommentCount,
    UserStatistics.UpVotes,
    UserStatistics.DownVotes,
    PostStatistics.Title,
    PostStatistics.CreationDate,
    PostStatistics.Score,
    PostStatistics.ViewCount,
    PostStatistics.AnswerCount,
    PostStatistics.CommentCount,
    PostStatistics.TagName
FROM UserStatistics
LEFT JOIN PostStatistics ON UserStatistics.PostCount > 0
ORDER BY UserStatistics.Reputation DESC, PostStatistics.CreationDate DESC;
