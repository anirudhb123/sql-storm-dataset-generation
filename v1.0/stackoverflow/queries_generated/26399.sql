WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.ViewCount IS NOT NULL THEN Posts.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN Posts.AnswerCount IS NOT NULL THEN Posts.AnswerCount ELSE 0 END) AS TotalAnswers
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(Comments.Score) AS TotalCommentScore,
        SUM(Votes.VoteTypeId = 2) AS UpVotes,
        SUM(Votes.VoteTypeId = 3) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Comments.UserId = Users.Id
    LEFT JOIN 
        Votes ON Votes.UserId = Users.Id
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        PostHistoryTypes.Name AS HistoryType,
        PostHistory.CreationDate AS HistoryDate,
        PostHistory.UserDisplayName,
        PostHistory.Text AS ChangeDescription
    FROM 
        PostHistory
    JOIN 
        Posts ON PostHistory.PostId = Posts.Id
    JOIN 
        PostHistoryTypes ON PostHistory.PostHistoryTypeId = PostHistoryTypes.Id
    WHERE 
        PostHistory.CreationDate > NOW() - INTERVAL '1 year'
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalAnswers,
    U.UserId,
    U.DisplayName,
    U.PostsCreated,
    U.TotalCommentScore,
    U.UpVotes,
    U.DownVotes,
    P.Title,
    P.HistoryType,
    P.HistoryDate,
    P.UserDisplayName AS Editor,
    P.ChangeDescription
FROM 
    TagStatistics T
JOIN 
    UserActivity U ON T.PostCount > 50
LEFT JOIN 
    PostHistoryDetails P ON P.PostId IN (
        SELECT Id FROM Posts WHERE Tags LIKE '%' || T.TagName || '%'
    )
ORDER BY 
    T.TotalViews DESC, 
    U.TotalCommentScore DESC
LIMIT 100;
