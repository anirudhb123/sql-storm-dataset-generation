WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, 1 AS Level
    FROM Users
    WHERE Reputation > 1000
    UNION ALL
    SELECT u.Id, u.Reputation, ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 10
), 
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
), 
ClosedPosts AS (
    SELECT p.Id AS PostId, 
           ph.CreationDate AS CloseDate,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS CloseAction
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 
    AND ph.UserId IS NOT NULL
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ur.Reputation, 0) AS ReputationLevel,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COALESCE(b.HighestBadgeClass, 0) AS HighestBadge,
    p.Title AS PostTitle,
    pa.CommentCount,
    pa.UpvoteCount,
    pa.DownvoteCount,
    cp.CloseDate,
    CASE WHEN cp.CloseDate IS NOT NULL THEN 'Closed' ELSE 'Active' END AS PostStatus
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN UserBadges b ON u.Id = b.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostActivity pa ON pa.PostId = p.Id
LEFT JOIN ClosedPosts cp ON cp.PostId = p.Id
WHERE u.Reputation > 500
ORDER BY ReputationLevel DESC, BadgeCount DESC, PostTitle ASC
OPTION (MAXRECURSION 100)

