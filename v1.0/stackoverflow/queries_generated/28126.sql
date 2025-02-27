WITH TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserBadges AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.OwnerUserId,
        COUNT(Comments.Id) AS CommentCount,
        Max(Posts.Score) AS Score
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostsStatistics.PostId,
        PostsStatistics.Title,
        PostsStatistics.CommentCount,
        PostsStatistics.Score,
        TagCounts.TagName,
        TagCounts.PostCount,
        TagCounts.TotalViews,
        TagCounts.TotalScore,
        UserBadges.DisplayName,
        UserBadges.BadgeCount
    FROM 
        PostStatistics AS PostsStatistics
    JOIN 
        TagCounts ON PostsStatistics.PostId = TagCounts.TagName
    JOIN 
        UserBadges ON PostsStatistics.OwnerUserId = UserBadges.UserId
    WHERE 
        PostsStatistics.Score > 0
        AND TagCounts.PostCount > 5
    ORDER BY 
        PostsStatistics.Score DESC, TagCounts.TotalViews DESC
)
SELECT 
    PostId,
    Title,
    CommentCount,
    Score,
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    DisplayName,
    BadgeCount
FROM 
    TopPosts
LIMIT 10;
