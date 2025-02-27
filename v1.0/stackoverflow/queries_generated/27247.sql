WITH TagAggregates AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        STRING_AGG(DISTINCT Posts.Title, '; ') AS PostTitles,
        STRING_AGG(DISTINCT CONCAT(Posts.OwnerDisplayName, ': ', Posts.Title), '; ') AS OwnersAndTitles
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagAggregates
    WHERE 
        PostCount > 5  -- Only consider tags with more than 5 posts
),
UserBadges AS (
    SELECT 
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount
    FROM 
        Users
    LEFT JOIN 
        Badges ON Badges.UserId = Users.Id
    GROUP BY 
        Users.DisplayName
)
SELECT 
    Tags.TagName,
    TagAggregates.PostCount,
    TagAggregates.TotalViews,
    TagAggregates.PostTitles,
    TagAggregates.OwnersAndTitles,
    TopTags.ViewRank,
    UserBadges.DisplayName AS MostActiveUser,
    UserBadges.BadgeCount
FROM 
    TagAggregates
JOIN 
    TopTags ON TagAggregates.TagName = TopTags.TagName
LEFT JOIN 
    UserBadges ON UserBadges.BadgeCount = (
        SELECT 
            MAX(BadgeCount) 
        FROM 
            UserBadges
    )
ORDER BY 
    TopTags.ViewRank;
