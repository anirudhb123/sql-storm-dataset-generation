WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        ARRAY_AGG(DISTINCT u.DisplayName) AS ActiveUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        t.IsModeratorOnly = 0
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        ActiveUsers,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    ActiveUsers,
    CONCAT('Top ', Rank, ' tag based on score') AS TagRank
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    TotalScore DESC;
