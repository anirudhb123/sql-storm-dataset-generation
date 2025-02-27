WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.Score,
           p.ViewCount,
           p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
           COUNT(DISTINCT p2.Id) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts,
           STRING_AGG(DISTINCT t.TagName, ', ') OVER (PARTITION BY p.Id) AS Tags
    FROM Posts p
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN Posts p2 ON pl.RelatedPostId = p2.Id
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT u.Id AS UserId, 
           COUNT(b.Id) AS BadgeCount,
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ActiveUsers AS (
    SELECT u.Id,
           u.DisplayName,
           u.Reputation,
           COALESCE(ub.BadgeCount, 0) AS BadgeCount,
           ub.BadgeNames
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 100
)

SELECT u.DisplayName,
       u.Reputation,
       COALESCE(rp.Title, 'No Posts') AS MostActivePostTitle,
       COALESCE(rp.Score, 0) AS PostScore,
       COALESCE(rp.ViewCount, 0) AS PostViewCount,
       u.BadgeCount,
       u.BadgeNames,
       u.Reputation * 0.01 AS ReputationRank -- Sample calculation
FROM ActiveUsers u
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE (u.BadgeCount > 0 AND u.Reputation > 200) OR (u.BadgeCount = 0 AND u.Reputation < 200)
ORDER BY u.Reputation DESC, u.BadgeCount DESC
LIMIT 50;

-- This query benchmarks performance across several constructs:
-- 1. CTEs for structured subquery hierarchy for cleanliness and reusability.
-- 2. Window functions for ranking and counting; allows comparison within partitions.
-- 3. Outer joins to manage data from different tables, ensuring visibility of all users and their interactions.
-- 4. String aggregation to consolidate tag data per post.
-- 5. Combined filtering logic to showcase how multiple executive conditions impact active user participation.
-- 6. Complex predicates that assess user rankings based on badges and reputation earning rules.
