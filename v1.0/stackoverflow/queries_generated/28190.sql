WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadgeCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('<', t.TagName, '>%')
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    WHERE t.IsModeratorOnly = 0
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        CommentCount,
        GoldBadgeCount,
        SilverBadgeCount,
        BronzeBadgeCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS Rank
    FROM TagStatistics
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    AverageScore,
    CommentCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount
FROM TopTags
WHERE Rank <= 10
ORDER BY Rank;
