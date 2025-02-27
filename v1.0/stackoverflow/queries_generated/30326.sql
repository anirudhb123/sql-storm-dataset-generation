WITH RecursivePostHierarchy AS (
    SELECT Id, ParentId, Title, CreationDate, 
           ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY CreationDate DESC) AS rn
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.ParentId, p.Title, p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserBadgeCounts AS (
    SELECT u.Id AS UserId, 
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularPosts AS (
    SELECT p.Id, p.Title, p.ViewCount, p.Score,
           DENSE_RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
           DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.Score,
    rph.Title AS RelatedPostTitle,
    rph.CreationDate AS RelatedPostDate
FROM Users u
JOIN UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN PopularPosts pp ON pp.ViewRank <= 5 OR pp.ScoreRank <= 5
LEFT JOIN RecursivePostHierarchy rph ON rph rn <= 3 AND pp.Id = rph.ParentId
WHERE ub.BadgeCount > 0
  AND (u.Reputation > 1000 OR pp.ViewCount > 100)
ORDER BY u.DisplayName, pp.ViewCount DESC, pp.Score DESC;
