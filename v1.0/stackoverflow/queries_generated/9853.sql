WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    GROUP BY 
        Tags.TagName
), UserBadges AS (
    SELECT 
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
), UserActivity AS (
    SELECT 
        Users.Id,
        Users.DisplayName,
        COUNT(Posts.Id) AS PostCount,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        MAX(Posts.CreationDate) AS LastPostDate
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    GROUP BY 
        Users.Id
), Combined AS (
    SELECT 
        ua.DisplayName,
        ua.PostCount,
        ua.CommentCount,
        ua.LastPostDate,
        ub.BadgeCount,
        ts.TagName,
        ts.PostCount AS TagPostCount,
        ts.TotalViews
    FROM 
        UserActivity ua
    JOIN 
        UserBadges ub ON ua.DisplayName = ub.DisplayName
    LEFT JOIN 
        TagStats ts ON ts.PostCount > 0
)
SELECT 
    DisplayName,
    PostCount,
    CommentCount,
    LastPostDate,
    BadgeCount,
    TagName,
    TagPostCount,
    TotalViews
FROM 
    Combined
ORDER BY 
    TotalViews DESC, PostCount DESC
FETCH FIRST 10 ROWS ONLY;
