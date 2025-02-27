
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.ViewCount) AS AverageViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserAggregates AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.AverageViews, 0) AS AverageViews,
        COALESCE(ps.LastPostDate, '1900-01-01') AS LastPostDate 
    FROM Users u
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT
    ua.DisplayName,
    ua.Reputation,
    ua.BadgeCount,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.AverageViews,
    ua.LastPostDate,
    CASE 
        WHEN ua.Reputation > 1000 AND ua.BadgeCount > 5 THEN 'High Performer'
        WHEN ua.Reputation > 1000 THEN 'Experienced'
        WHEN ua.BadgeCount > 5 THEN 'Enthusiast'
        ELSE 'Newcomer'
    END AS UserCategory,
    GROUP_CONCAT(DISTINCT t.TagName) AS AssociatedTags,
    COUNT(DISTINCT v.Id) AS VoteCount,
    GROUP_CONCAT(DISTINCT CONCAT(vt.Name, ' (', v.CreationDate, ')') ORDER BY v.CreationDate DESC SEPARATOR '; ') AS LatestVotes
FROM UserAggregates ua
LEFT JOIN Posts p ON ua.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN (
    SELECT 
        t.TagName
    FROM (
        SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
        FROM (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers INNER JOIN Posts p ON CHAR_LENGTH(p.Tags)
        -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t
) AS t ON true
GROUP BY ua.Id, ua.DisplayName, ua.Reputation, ua.BadgeCount, ua.TotalPosts, ua.Questions, ua.Answers, ua.AverageViews, ua.LastPostDate
HAVING COUNT(DISTINCT p.Id) > 0
ORDER BY ua.Reputation DESC, ua.TotalPosts DESC
LIMIT 10;
