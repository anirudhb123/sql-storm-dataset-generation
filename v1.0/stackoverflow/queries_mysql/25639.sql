
WITH TagAnalysis AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        GROUP_CONCAT(DISTINCT p.OwnerDisplayName ORDER BY p.OwnerDisplayName SEPARATOR ', ') AS UniqueAuthors,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
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
        UserBadgeCount ub ON FIND_IN_SET(ub.DisplayName, ta.UniqueAuthors) > 0
    ORDER BY 
        ta.PostCount DESC, 
        ta.TotalViews DESC
    LIMIT 10
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
