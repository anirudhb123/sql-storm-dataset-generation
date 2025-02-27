WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS UserNames
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(STRING_TO_ARRAY(SUBSTRING(Posts.Tags, 2, LENGTH(Posts.Tags) - 2), '><')::int[])
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
        AverageScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 10
)

SELECT 
    PT.TagName,
    PT.PostCount,
    PT.TotalViews,
    PT.AverageScore,
    PT.Rank,
    PH.UserDisplayName,
    PH.CreationDate AS LastEdit,
    PH.Comment AS LastEditComment,
    PH.Text AS LastEditText
FROM 
    PopularTags PT
LEFT JOIN 
    PostHistory PH ON PT.TagName = ANY(STRING_TO_ARRAY(SUBSTRING(PH.Text, 2, LENGTH(PH.Text) - 2), '><')::text[])
WHERE 
    PH.PostHistoryTypeId IN (4, 5, 6)
ORDER BY 
    PT.Rank, PT.TagName;
