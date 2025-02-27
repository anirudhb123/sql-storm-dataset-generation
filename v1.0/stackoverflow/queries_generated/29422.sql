WITH TagStats AS (
    SELECT
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers,
        SUM(Posts.Score) AS TotalScore,
        AVG(Users.Reputation) AS AverageUserReputation
    FROM
        Tags
    JOIN
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><')::int[])
    JOIN
        Users ON Posts.OwnerUserId = Users.Id
    WHERE
        Posts.CreationDate >= DATEADD(year, -1, CURRENT_TIMESTAMP) -- Posts created in the last year
    GROUP BY
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        TotalAnswers,
        TotalScore,
        AverageUserReputation,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    TagName,
    TotalViews,
    TotalAnswers,
    TotalScore,
    AverageUserReputation
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    TotalViews DESC;
