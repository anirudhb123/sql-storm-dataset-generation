WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Users.Reputation) AS AvgUserReputation
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
PostEngagement AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        COUNT(Comments.Id) AS CommentCount,
        SUM(Votes.VoteTypeId = 2) AS UpVotes, -- UpMod
        SUM(Votes.VoteTypeId = 3) AS DownVotes -- DownMod
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Comments.PostId = Posts.Id
    LEFT JOIN 
        Votes ON Votes.PostId = Posts.Id
    WHERE 
        Posts.CreationDate >= DATEADD(DAY, -365, GETDATE()) 
    GROUP BY 
        Posts.Id
),
PostHistorySummary AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(PostHistory.Id) AS EditCount,
        MAX(PostHistory.CreationDate) AS LastEditDate,
        MAX(PostHistory.UserDisplayName) AS LastEditedBy
    FROM 
        Posts
    LEFT JOIN 
        PostHistory ON PostHistory.PostId = Posts.Id
    GROUP BY 
        Posts.Id
)
SELECT 
    TagStats.TagName,
    TagStats.PostCount,
    TagStats.TotalViews,
    TagStats.AvgUserReputation,
    PostEngagement.Title AS PostTitle,
    PostEngagement.CommentCount,
    PostEngagement.UpVotes,
    PostEngagement.DownVotes,
    PostHistorySummary.EditCount,
    PostHistorySummary.LastEditDate,
    PostHistorySummary.LastEditedBy
FROM 
    TagStats
LEFT JOIN 
    PostEngagement ON TagStats.PostCount > 0
LEFT JOIN 
    PostHistorySummary ON PostHistorySummary.PostId = PostEngagement.PostId
ORDER BY 
    TagStats.TotalViews DESC, TagStats.PostCount DESC;
