
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
), 
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
), 
UserBadges AS (
    SELECT 
        b.UserId,
        SUM(IF(b.Class = 1, 1, 0)) AS GoldBadges,
        SUM(IF(b.Class = 2, 1, 0)) AS SilverBadges,
        SUM(IF(b.Class = 3, 1, 0)) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    us.AverageScore,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    pt.TagName,
    pt.PostCount,
    pt.TotalViews
FROM UserStatistics us
LEFT JOIN UserBadges ub ON us.UserId = ub.UserId
LEFT JOIN PopularTags pt ON pt.TagName IN (
    SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS TagName
    FROM Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
)
ORDER BY us.TotalPosts DESC, us.AverageScore DESC
LIMIT 50;
