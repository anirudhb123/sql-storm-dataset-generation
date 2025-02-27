WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(Posts.ViewCount) AS TotalPostViews,
        SUM(Posts.Score) AS TotalPostScore,
        SUM(COALESCE(Comments.Score, 0)) AS TotalCommentScore
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    GROUP BY 
        Users.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PostHistory.PostId,
        COUNT(CASE WHEN PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount,
        COUNT(CASE WHEN PostHistoryTypeId = 11 THEN 1 END) AS ReopenVoteCount,
        COUNT(CASE WHEN PostHistoryTypeId = 12 THEN 1 END) AS DeleteVoteCount,
        MIN(PostHistory.CreationDate) AS FirstModifiedDate
    FROM 
        PostHistory
    GROUP BY 
        PostHistory.PostId
)
SELECT 
    tags.TagName,
    tagStats.PostCount,
    tagStats.TotalViews,
    tagStats.TotalScore,
    tagStats.AverageScore,
    userActivity.DisplayName,
    userActivity.TotalPosts,
    userActivity.TotalPostViews,
    userActivity.TotalPostScore,
    userActivity.TotalCommentScore,
    phs.CloseVoteCount,
    phs.ReopenVoteCount,
    phs.DeleteVoteCount,
    phs.FirstModifiedDate
FROM 
    TagStats AS tagStats
JOIN 
    UserActivity AS userActivity ON tagStats.PostCount > 0
JOIN 
    PostHistorySummary AS phs ON phs.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || tagStats.TagName || '%')
WHERE 
    tagStats.TotalViews > 1000
ORDER BY 
    tagStats.AverageScore DESC, 
    userActivity.TotalPostViews DESC
LIMIT 100;
