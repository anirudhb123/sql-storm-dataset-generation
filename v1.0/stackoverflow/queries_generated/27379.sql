WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Badges.Id) AS BadgeCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Users.Reputation) AS TotalReputation
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Tags.TagName
),
ActiveUsers AS (
    SELECT 
        Users.DisplayName,
        Users.Reputation,
        Users.Views,
        COUNT(DISTINCT Posts.Id) AS ActivePostCount,
        COUNT(DISTINCT Comments.Id) AS ActiveCommentCount,
        COUNT(DISTINCT Badges.Id) AS ActiveBadgeCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    WHERE 
        Users.LastAccessDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        Users.DisplayName, Users.Reputation, Users.Views
),
TotalStatistics AS (
    SELECT 
        COUNT(DISTINCT Users.Id) AS TotalUsers,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        COUNT(DISTINCT Badges.Id) AS TotalBadges
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.CommentCount,
    ts.BadgeCount,
    ts.TotalViews,
    ts.TotalReputation,
    au.DisplayName AS ActiveUser,
    au.Reputation AS ActiveUserReputation,
    au.ActivePostCount,
    au.ActiveCommentCount,
    au.ActiveBadgeCount,
    Totals.TotalUsers,
    Totals.TotalPosts,
    Totals.TotalComments,
    Totals.TotalBadges
FROM 
    TagStatistics ts
LEFT JOIN 
    ActiveUsers au ON ts.TotalReputation > 1000 -- Example condition for activity
CROSS JOIN 
    TotalStatistics Totals
ORDER BY 
    ts.TotalViews DESC, ts.PostCount DESC;
