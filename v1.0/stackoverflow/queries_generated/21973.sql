WITH UserBadges AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users
    LEFT JOIN Badges ON Users.Id = Badges.UserId
    GROUP BY Users.Id, Users.DisplayName
),
RecentPosts AS (
    SELECT 
        Posts.OwnerUserId,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AvgScore,
        RANK() OVER (PARTITION BY Posts.OwnerUserId ORDER BY Posts.CreationDate DESC) AS RecentRank
    FROM Posts
    WHERE Posts.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY Posts.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(p.TotalPosts, 0) AS TotalPosts,
    COALESCE(p.Questions, 0) AS TotalQuestions,
    COALESCE(p.Answers, 0) AS TotalAnswers,
    COALESCE(p.TotalViews, 0) AS TotalViews,
    COALESCE(p.AvgScore, 0) AS AvgScore
FROM UserBadges b
FULL OUTER JOIN RecentPosts p ON b.UserId = p.OwnerUserId
FULL OUTER JOIN Users u ON COALESCE(p.OwnerUserId, b.UserId) = u.Id
WHERE u.Reputation > 0 
  AND (COALESCE(b.BadgeCount, 0) > 3 OR COALESCE(p.TotalPosts, 0) > 5)
  AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
ORDER BY u.Reputation DESC
LIMIT 100;

-- Optional complexity demonstrating potential SQL corner cases
SELECT 
    *,
    CASE WHEN p.OwnerUserId IS NULL THEN 'No posts' ELSE 'Has posts' END AS PostStatus,
    CASE WHEN b.BadgeCount IS NULL THEN 'No badges' ELSE 
         CASE WHEN b.BadgeCount >= 10 THEN 'High badge count'
              ELSE 'Moderate badge count' END END AS BadgeStatus
FROM UserBadges b
RIGHT JOIN Posts p ON b.UserId = p.OwnerUserId
WHERE p.ViewCount IS NOT NULL 
  AND (p.LastActivityDate >= NOW() - INTERVAL '30 days' OR p.Score = 0)
ORDER BY p.ViewCount DESC NULLS LAST;

-- String manipulation demonstrating quirky semantics
SELECT 
    p.Title,
    TRIM(BOTH ' ' FROM REPLACE(p.Body, '<p>', '')) AS CleanedBody,
    INITCAP(REPLACE(p.Tags, '<tag>', '')) AS FormattedTags
FROM Posts p
WHERE p.Body IS NOT NULL
  AND p.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE ViewCount IS NOT NULL)
ORDER BY LENGTH(p.Title) DESC
LIMIT 50;
