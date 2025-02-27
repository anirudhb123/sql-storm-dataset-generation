WITH RECURSIVE UserHierarchy AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, 
           1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000
    UNION ALL
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.Id -- Recursive joining on user table
    WHERE u.Reputation > 1000 AND uh.Level < 5
),
PostRanking AS (
    SELECT p.Id AS PostId, p.Title, p.ViewCount, p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2) -- Questions and Answers
),
RecentClosures AS (
    SELECT ph.PostId, ph.CreationDate, ph.Comment, ph.UserDisplayName
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Post Closed and Post Reopened
    AND ph.CreationDate >= NOW() - INTERVAL '30 days'
),
UserBadges AS (
    SELECT u.Id AS UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT uh.DisplayName, r.PostId, r.Title, COUNT(c.Id) AS CommentCount, 
       COALESCE(ub.GoldBadges, 0) AS GoldBadges,
       COALESCE(ub.SilverBadges, 0) AS SilverBadges,
       COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
       SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS ClosureCount
FROM UserHierarchy uh
JOIN PostRanking r ON uh.Id = r.OwnerUserId
LEFT JOIN Comments c ON r.PostId = c.PostId
LEFT JOIN UserBadges ub ON uh.Id = ub.UserId
LEFT JOIN RecentClosures ph ON r.PostId = ph.PostId
WHERE uh.Reputation > 1000
AND r.ViewRank <= 5
GROUP BY uh.DisplayName, r.PostId, r.Title, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY uh.Reputation DESC, COUNT(c.Id) DESC;
