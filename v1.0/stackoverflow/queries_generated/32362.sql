WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, 1 AS Level
    FROM Users
    WHERE Reputation > 1000  -- Starting point for users with high reputation

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, h.Level + 1
    FROM Users u
    JOIN UserHierarchy h ON u.Reputation < h.Reputation
    WHERE h.Level < 5  -- Stop after 5 levels of hierarchy
),

RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts created in the last 30 days
),

PostVoteStats AS (
    SELECT PostId, 
           COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),

UserPosts AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COALESCE(rp.PostId, 0) AS RecentPostId, 
           rp.Title AS RecentPostTitle, 
           COALESCE(rp.CreationDate, '1970-01-01') AS RecentPostDate,
           COALESCE(rps.UpVotes, 0) AS RecentPostUpVotes,
           COALESCE(rps.DownVotes, 0) AS RecentPostDownVotes
    FROM Users u
    LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN PostVoteStats rps ON rp.PostId = rps.PostId
    WHERE u.Reputation > 5000  -- Consider only reputed users
),

UserBadges AS (
    SELECT b.UserId, 
           COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges, 
           COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)

SELECT uh.DisplayName AS UserName, 
       uh.Reputation,
       ub.GoldBadges, 
       ub.SilverBadges, 
       ub.BronzeBadges,
       up.RecentPostTitle,
       up.RecentPostDate,
       up.RecentPostUpVotes,
       up.RecentPostDownVotes,
       CASE 
           WHEN up.RecentPostId IS NOT NULL THEN 'Active'
           ELSE 'Inactive'
       END AS PostStatus
FROM UserHierarchy uh
LEFT JOIN UserPosts up ON uh.Id = up.UserId
LEFT JOIN UserBadges ub ON uh.Id = ub.UserId
ORDER BY uh.Reputation DESC, up.RecentPostDate DESC
LIMIT 100;  -- Limit to top 100 users for performance benchmarking
