WITH RECURSIVE TagHierarchy AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        Tags.TagName
),
SuperUsers AS (
    SELECT 
        Users.Id,
        Users.DisplayName,
        SUM(Badges.Class) AS TotalBadgePoints,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(Posts.ViewCount) AS TotalPostViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
    HAVING 
        COUNT(Posts.Id) > 5 AND 
        SUM(Badges.Class) > 2
),
PopularTags AS (
    SELECT 
        TagHierarchy.TagName,
        TagHierarchy.PostCount,
        COUNT(Posts.Id) AS TotalPostScore,
        RANK() OVER (ORDER BY TagHierarchy.PostCount DESC) AS TagRank
    FROM 
        TagHierarchy
    LEFT JOIN 
        Posts ON Posts.Tags LIKE '%' || TagHierarchy.TagName || '%'
    GROUP BY 
        TagHierarchy.TagName, TagHierarchy.PostCount
    HAVING 
        TagHierarchy.PostCount > 10
)
SELECT 
    Users.DisplayName AS UserName,
    SuperUsers.TotalBadgePoints,
    SuperUsers.TotalPosts,
    SuperUsers.TotalPostViews,
    SuperUsers.TotalScore,
    PopularTags.TagName,
    PopularTags.PostCount,
    PopularTags.TotalPostScore
FROM 
    SuperUsers
JOIN 
    PopularTags ON SuperUsers.TotalPosts > 1
ORDER BY 
    SuperUsers.TotalScore DESC, 
    PopularTags.PostCount DESC
LIMIT 10;
