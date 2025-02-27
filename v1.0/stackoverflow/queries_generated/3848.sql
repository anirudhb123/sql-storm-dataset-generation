WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostScoreRank AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageScore,
    ub.DisplayName AS TopUser,
    ub.BadgeCount,
    ub.MaxBadgeClass,
    psr.Title AS TopPostTitle,
    psr.Score AS TopPostScore,
    psr.ScoreRank
FROM TagStats ts
JOIN UserBadges ub ON ub.BadgeCount > 5
LEFT JOIN PostScoreRank psr ON psr.ScoreRank = 1
WHERE ts.PostCount > 0
ORDER BY ts.PostCount DESC, ts.TotalViews DESC;
