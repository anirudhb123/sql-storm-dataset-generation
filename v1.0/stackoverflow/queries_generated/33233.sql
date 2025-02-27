WITH RECURSIVE TagPostCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = Posts.Id
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(Comments.Id, 0)) AS CommentCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    GROUP BY 
        Users.Id
),
PostHistorySummary AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        MAX(CASE WHEN PostHistoryTypeId = 2 THEN CreationDate END) AS InitialBodyDate,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS ClosedDate,
        COUNT(*) FILTER (WHERE PostHistoryTypeId IN (24, 52, 53)) AS EditCount
    FROM 
        Posts
    LEFT JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    GROUP BY 
        Posts.Id
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalViews,
    ua.TotalPosts,
    ua.QuestionCount,
    ua.CommentCount,
    COALESCE(tpc.PostCount, 0) AS TotalTags,
    phs.PostId,
    phs.Title,
    phs.InitialBodyDate,
    phs.ClosedDate,
    phs.EditCount
FROM 
    UserActivity ua
LEFT JOIN 
    TagPostCounts tpc ON ua.TotalPosts = tpc.PostCount
LEFT JOIN 
    PostHistorySummary phs ON ua.TotalPosts = (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = ua.UserId)
ORDER BY 
    ua.TotalViews DESC, 
    ua.TotalPosts DESC;
