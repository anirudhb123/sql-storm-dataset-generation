WITH TagStatistics AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        AVG(COALESCE(Posts.AnswerCount, 0)) AS AvgAnswerCount
    FROM Tags
    LEFT JOIN Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    GROUP BY Tags.TagName
),
UserStatistics AS (
    SELECT
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS TotalDownvotes,
        SUM(COALESCE(Comments.Id, 0)) AS TotalComments
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    GROUP BY Users.DisplayName
),
PostActivity AS (
    SELECT
        Posts.Id AS PostId,
        Posts.Title,
        Posts.ViewCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount,
        COUNT(DISTINCT PostHistory.Id) AS EditCount
    FROM Posts
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN PostHistory ON Posts.Id = PostHistory.PostId
    GROUP BY Posts.Id
),
TagUserEngagement AS (
    SELECT
        t.TagName,
        u.DisplayName,
        SUM(COALESCE(pa.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(pa.VoteCount, 0)) AS TotalVotes
    FROM TagStatistics t
    JOIN Posts p ON t.TagName = ANY(string_to_array(p.Tags, '><'))
    JOIN UserStatistics u ON p.OwnerUserId = u.UserId
    LEFT JOIN PostActivity pa ON p.Id = pa.PostId
    GROUP BY t.TagName, u.DisplayName
)

SELECT
    tue.TagName,
    tue.DisplayName,
    tue.TotalComments,
    tue.TotalVotes,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalScore,
    us.PostsCreated,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.TotalComments AS UserTotalComments,
    ROUND(AVG(NULLIF(ts.TotalScore, 0)), 2) AS AvgPostScore
FROM TagUserEngagement tue
JOIN TagStatistics ts ON tue.TagName = ts.TagName
JOIN UserStatistics us ON tue.DisplayName = us.DisplayName
GROUP BY tue.TagName, tue.DisplayName, ts.PostCount, ts.TotalViews, ts.TotalScore, us.PostsCreated, us.TotalUpvotes, us.TotalDownvotes, UserTotalComments
ORDER BY ts.TotalScore DESC, tue.TotalVotes DESC, tue.TagName, tue.DisplayName;
