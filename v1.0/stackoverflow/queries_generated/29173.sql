WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserBadges AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(CASE WHEN Badges.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Badges.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Badges.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
),
UserPostStats AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(Posts.Id) AS TotalPosts,
        COUNT(CASE WHEN Posts.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN Posts.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id
)
SELECT 
    Users.DisplayName,
    UserPostStats.TotalPosts,
    UserPostStats.Questions,
    UserPostStats.Answers,
    UserPostStats.TotalViews,
    UserPostStats.TotalScore,
    UserBadges.GoldBadges,
    UserBadges.SilverBadges,
    UserBadges.BronzeBadges,
    TagStats.TagName,
    TagStats.PostCount,
    TagStats.TotalViews AS TagTotalViews,
    TagStats.TotalScore AS TagTotalScore
FROM 
    Users
JOIN 
    UserPostStats ON Users.Id = UserPostStats.UserId
JOIN 
    UserBadges ON Users.Id = UserBadges.UserId
LEFT JOIN 
    TagStats ON TagStats.TagName IN (SELECT UNNEST(string_to_array(substring(Post.Tags, 2, length(Post.Tags) - 2), '><'))
                                        FROM Posts AS Post WHERE Post.OwnerUserId = Users.Id)
WHERE 
    UserPostStats.TotalPosts > 10    -- Filter for users with more than 10 posts
ORDER BY 
    UserPostStats.TotalScore DESC,    -- Order by total score
    Users.DisplayName ASC;             -- Then by display name
