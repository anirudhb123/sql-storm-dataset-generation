WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        AVG(Posts.Score) AS AverageScore,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserEngagement AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCreated,
        SUM(COALESCE(Votes.Id, 0)) AS TotalVotes,
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
PostHistoryChanges AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(CASE WHEN PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount,
        COUNT(CASE WHEN PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory
    JOIN 
        Posts ON PostHistory.PostId = Posts.Id
    GROUP BY 
        Posts.Id
)
SELECT 
    Tags.TagName,
    TagStatistics.PostCount,
    TagStatistics.AverageScore,
    TagStatistics.TotalViews,
    TagStatistics.QuestionCount,
    TagStatistics.AnswerCount,
    UserEngagement.DisplayName,
    UserEngagement.PostsCreated,
    UserEngagement.TotalVotes,
    UserEngagement.TotalComments,
    PostHistoryChanges.EditCount,
    PostHistoryChanges.CloseCount,
    PostHistoryChanges.ReopenCount
FROM 
    TagStatistics
JOIN 
    UserEngagement ON UserEngagement.PostsCreated > 0
JOIN 
    PostHistoryChanges ON PostHistoryChanges.PostId = (
        SELECT Id 
        FROM Posts 
        WHERE Tags LIKE '%' || TagStatistics.TagName || '%'
        LIMIT 1
    )
WHERE 
    TagStatistics.PostCount > 10
ORDER BY 
    TagStatistics.TotalViews DESC, 
    UserEngagement.PostsCreated DESC;
