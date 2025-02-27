WITH TagStats AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        AVG(COALESCE(Posts.AnswerCount, 0)) AS AvgAnswerCount,
        AVG(COALESCE(Posts.CommentCount, 0)) AS AvgCommentCount
    FROM
        Tags
    LEFT JOIN
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY
        Tags.TagName
),
UserActivity AS (
    SELECT
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)::int) AS TotalUpVotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)::int) AS TotalDownVotes,
        SUM(COALESCE(Comments.Id, 0)) AS TotalComments
    FROM
        Users
    LEFT JOIN
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN
        Comments ON Posts.Id = Comments.PostId
    GROUP BY
        Users.Id, Users.DisplayName
),
PostHistoryCounts AS (
    SELECT
        Posts.Id AS PostId,
        COUNT(PostHistory.Id) AS EditCount,
        COUNT(DISTINCT CASE WHEN PostHistory.PostHistoryTypeId IN (10, 11) THEN PostHistory.id END) AS CloseOpenCount
    FROM
        Posts
    LEFT JOIN
        PostHistory ON Posts.Id = PostHistory.PostId
    GROUP BY
        Posts.Id
)

SELECT
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalScore,
    ts.AvgAnswerCount,
    ts.AvgCommentCount,
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalComments,
    phc.EditCount,
    phc.CloseOpenCount
FROM
    TagStats ts
JOIN
    UserActivity ua ON ts.PostCount > 0  -- Only consider users with posts related to tags
JOIN
    Posts p ON TRUE  -- Cross join to gather all data
JOIN
    PostHistoryCounts phc ON p.Id = phc.PostId
ORDER BY
    ts.TotalViews DESC,
    ua.TotalUpVotes DESC;
