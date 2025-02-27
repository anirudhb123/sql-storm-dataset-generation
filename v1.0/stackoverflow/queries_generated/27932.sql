WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore,
        STRING_AGG(DISTINCT Posts.OwnerDisplayName, ', ') AS Owners
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, LENGTH(Posts.Tags) - 2), '><')::int[])
    WHERE 
        Tags.IsModeratorOnly = 0
    GROUP BY 
        Tags.TagName
),

TopUsers AS (
    SELECT 
        Users.DisplayName,
        SUM(Posts.ViewCount) AS UserTotalViews,
        RANK() OVER (ORDER BY SUM(Posts.ViewCount) DESC) AS UserRank
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.DisplayName
    HAVING 
        SUM(Posts.ViewCount) > 10000  -- Only consider users with significant views
),

PopularTags AS (
    SELECT 
        TagStats.TagName,
        TagStats.PostCount,
        TagStats.TotalViews,
        TagStats.AverageScore,
        TagStats.Owners,
        RANK() OVER (ORDER BY TagStats.TotalViews DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        TagStats.PostCount > 5  -- Tags with more than 5 posts
)

SELECT 
    PopularTags.TagName,
    PopularTags.PostCount,
    PopularTags.TotalViews,
    PopularTags.AverageScore,
    PopularTags.Owners,
    TopUsers.DisplayName AS TopOwner,
    TopUsers.UserTotalViews,
    TopUsers.UserRank
FROM 
    PopularTags
LEFT JOIN 
    TopUsers ON PopularTags.Owners LIKE '%' || TopUsers.DisplayName || '%'
WHERE 
    PopularTags.TagRank <= 10  -- Retrieve only top 10 tags
ORDER BY 
    PopularTags.TotalViews DESC;
