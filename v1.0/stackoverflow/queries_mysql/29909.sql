
WITH TagAggregates AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AvgScore,
        GROUP_CONCAT(DISTINCT Users.DisplayName ORDER BY Users.DisplayName SEPARATOR ', ') AS Contributors
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%<', Tags.TagName, '>%')
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgScore,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagAggregates, (SELECT @rownum := 0) r
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
),
TopContributors AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS ContributedPosts,
        SUM(Posts.ViewCount) AS TotalViews
    FROM 
        Users
    JOIN 
        Posts ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        Users.DisplayName
    ORDER BY 
        ContributedPosts DESC
    LIMIT 10
)

SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.AvgScore,
    c.DisplayName AS TopContributor,
    c.ContributedPosts,
    c.TotalViews AS ContributorTotalViews
FROM 
    TopTags t
LEFT JOIN 
    TopContributors c ON c.ContributedPosts = (
        SELECT MAX(ContributedPosts)
        FROM TopContributors
    )
WHERE 
    t.Rank <= 10
ORDER BY 
    t.PostCount DESC;
