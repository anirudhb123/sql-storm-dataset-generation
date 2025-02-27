WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName AS OwnerName,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
      AND p.Score > 0
),
FilteredUsers AS (
    SELECT u.Id, u.Reputation, u.Views,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
           COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- BountyStart, BountyClose
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
),
TopBadges AS (
    SELECT UserId, COUNT(*) AS TotalBadges 
    FROM Badges 
    GROUP BY UserId 
    HAVING COUNT(*) > 2
),
ClosedPosts AS (
    SELECT p.Id, p.Title, ph.CreationDate AS ClosedDate, c.Name AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE ph.PostHistoryTypeId = 10
      AND ph.CreationDate >= NOW() - INTERVAL '90 days'
)
SELECT u.Id AS UserId, u.DisplayName, u.Reputation, u.Views, u.TotalBounties, 
       COUNT(DISTINCT rb.Id) AS RecentBadges, 
       COALESCE(cp.TotalClosedPosts, 0) AS TotalClosedPosts
FROM Users u
JOIN FilteredUsers fu ON u.Id = fu.Id
LEFT JOIN TopBadges tb ON u.Id = tb.UserId
LEFT JOIN ClosedPosts cp ON u.Id = (SELECT DISTINCT pp.OwnerUserId
                                    FROM Posts pp 
                                    WHERE pp.Id IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId = 10))
LEFT JOIN Badges rb ON u.Id = rb.UserId
WHERE u.LastAccessDate >= NOW() - INTERVAL '1 year'
GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views, u.TotalBounties, cp.TotalClosedPosts
ORDER BY u.Reputation DESC, RecentBadges DESC
FETCH FIRST 100 ROWS ONLY;
