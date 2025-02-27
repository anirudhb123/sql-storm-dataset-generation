
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(CASE WHEN v.VoteTypeId = 2 THEN 1 END, 0)) AS UpVotes,
        SUM(IFNULL(CASE WHEN v.VoteTypeId = 3 THEN 1 END, 0)) AS DownVotes,
        @rank := @rank + 1 AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    LEFT JOIN Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rank := 0) r
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY Tag
    ORDER BY TagCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalViews,
    ua.UpVotes,
    ua.DownVotes,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    pt.Tag,
    pt.TagCount,
    RANK() OVER (ORDER BY ua.TotalViews DESC) AS ViewRank
FROM UserActivity ua
LEFT JOIN UserBadges ub ON ua.UserId = ub.UserId
JOIN PopularTags pt ON ua.PostCount > 5
WHERE ua.PostCount > 0 AND (ua.TotalViews IS NOT NULL OR ua.UpVotes > 0)
ORDER BY ua.PostCount DESC, ua.TotalViews DESC;
