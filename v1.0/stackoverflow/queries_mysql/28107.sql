
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AverageScore,
        SUM(CASE WHEN u.Reputation IS NOT NULL THEN u.Reputation ELSE 0 END) AS TotalUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        TotalUserReputation,
        @row_num := @row_num + 1 AS TagRank
    FROM 
        TagStatistics, (SELECT @row_num := 0) r
    ORDER BY 
        PostCount DESC, TotalViews DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    pt.TagName,
    pt.PostCount,
    pt.TotalViews,
    pt.AverageScore,
    pt.TotalUserReputation,
    ub.UserId,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    PopularTags pt
JOIN 
    UserBadges ub ON pt.TagRank BETWEEN 1 AND 10
ORDER BY 
    pt.PostCount DESC, pt.TotalViews DESC, ub.BadgeCount DESC;
