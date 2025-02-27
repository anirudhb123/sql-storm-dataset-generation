WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        AVG(Posts.AnswerCount) AS AvgAnswers,
        AVG(Posts.CommentCount) AS AvgComments
    FROM 
        Tags 
        JOIN Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(COALESCE(Votes.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(Votes.VoteTypeId = 3, 0)) AS TotalDownvotes
    FROM 
        Users 
        LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId 
        LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
),
HighScores AS (
    SELECT 
        TagStats.TagName,
        TagStats.PostCount,
        TagStats.TotalViews,
        TagStats.TotalScore,
        TagStats.AvgAnswers,
        TagStats.AvgComments,
        UserActivity.DisplayName AS TopContributor,
        UserActivity.TotalPosts
    FROM 
        TagStats
        JOIN UserActivity ON UserActivity.TotalPosts = (
            SELECT 
                MAX(TotalPosts) 
            FROM 
                UserActivity
        )
    WHERE 
        TagStats.PostCount > 0
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    AvgAnswers,
    AvgComments,
    TopContributor,
    TotalPosts
FROM 
    HighScores
ORDER BY 
    TotalScore DESC, 
    PostCount DESC, 
    TotalViews DESC;
