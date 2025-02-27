WITH RecursivePostLinks AS (
    SELECT pl.PostId, pl.RelatedPostId, 1 AS LinkDepth
    FROM PostLinks pl
    WHERE pl.LinkTypeId = 1  -- Linked

    UNION ALL

    SELECT pl.PostId, pl.RelatedPostId, rpl.LinkDepth + 1
    FROM PostLinks pl
    JOIN RecursivePostLinks rpl ON pl.PostId = rpl.RelatedPostId
    WHERE pl.LinkTypeId = 1 AND rpl.LinkDepth < 5  -- Limit recursion depth to prevent infinite loops
),
ActiveUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart or BountyClose
    WHERE u.Reputation > 1000
    GROUP BY u.Id
),
UserBadges AS (
    SELECT b.UserId, STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Class = 1  -- Only Gold badges
    GROUP BY b.UserId
),
PostMetrics AS (
    SELECT p.Id AS PostId, p.Title, p.Score,
           COUNT(c.Id) AS CommentCount,
           MAX(ph.CreationDate) AS LastEditDate,
           ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.Score
)
SELECT au.DisplayName,
       au.Reputation,
       COALESCE(ub.BadgeNames, 'None') AS GoldBadges,
       COUNT(DISTINCT pl.RelatedPostId) AS LinkedPosts,
       SUM(CASE WHEN pm.EditRank = 1 THEN 1 ELSE 0 END) AS PostsEdited,
       SUM(CASE WHEN pm.CommentCount > 0 THEN 1 ELSE 0 END) AS PostsWithComments,
       SUM(pm.Score) AS TotalScore
FROM ActiveUsers au
LEFT JOIN UserBadges ub ON au.Id = ub.UserId
LEFT JOIN RecursivePostLinks rpl ON au.PostCount > 0 -- Only if user has posts
LEFT JOIN PostMetrics pm ON rpl.PostId = pm.PostId
GROUP BY au.DisplayName, au.Reputation, ub.BadgeNames
HAVING COUNT(DISTINCT pl.RelatedPostId) > 0
ORDER BY au.Reputation DESC, TotalScore DESC
LIMIT 10;
