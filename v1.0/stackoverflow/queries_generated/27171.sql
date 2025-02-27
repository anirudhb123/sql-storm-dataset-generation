WITH TagStats AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS ContributingUsers
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        ContributingUsers,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStats
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        ContributingUsers
    FROM 
        PopularTags 
    WHERE 
        ScoreRank <= 10 OR ViewRank <= 10
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    ContributingUsers,
    CASE 
        WHEN ScoreRank <= 10 THEN 'Top Score'
        ELSE 'Not Top Score'
    END AS ScoreCategory,
    CASE 
        WHEN ViewRank <= 10 THEN 'Top Views'
        ELSE 'Not Top Views'
    END AS ViewCategory
FROM 
    TopTags
ORDER BY 
    TotalScore DESC, TotalViews DESC;
