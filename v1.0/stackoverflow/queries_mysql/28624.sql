
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        GROUP_CONCAT(DISTINCT u.DisplayName) AS UsersContributing,
        GROUP_CONCAT(DISTINCT p.Title SEPARATOR '; ') AS PostTitles
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')  
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR  
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        UsersContributing,
        PostTitles,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.TotalViews,
    pt.TotalScore,
    pt.Rank,
    pt.UsersContributing,
    pt.PostTitles
FROM 
    PopularTags pt
WHERE 
    pt.Rank <= 5  
ORDER BY 
    pt.TotalScore DESC;
