
WITH TagAnalysis AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.OwnerDisplayName, ', ') AS UniqueAuthors,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        AVG(ISNULL(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
    GROUP BY 
        t.TagName
), 
UserBadgeCount AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
),
TopTags AS (
    SELECT 
        ta.TagName,
        ta.PostCount,
        ta.UniqueAuthors,
        ta.TotalViews,
        ta.AverageScore,
        ub.BadgeCount
    FROM 
        TagAnalysis ta
    JOIN 
        UserBadgeCount ub ON CHARINDEX(ub.DisplayName, ta.UniqueAuthors) > 0
    ORDER BY 
        ta.PostCount DESC, 
        ta.TotalViews DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.UniqueAuthors,
    tt.TotalViews,
    tt.AverageScore,
    tt.BadgeCount
FROM 
    TopTags tt;
