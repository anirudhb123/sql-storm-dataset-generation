
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        LISTAGG(DISTINCT u.DisplayName, ', ') AS UsersContributing,
        LISTAGG(DISTINCT p.Title, '; ') AS PostTitles
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'  
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'  
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
