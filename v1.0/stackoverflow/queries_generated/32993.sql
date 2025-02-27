WITH RECURSIVE UserScoreCTE AS (
    SELECT 
        Id AS UserId, 
        Reputation AS TotalReputation,
        CreationDate,
        LastAccessDate,
        Location,
        EmailHash,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000 -- starting point for users with reputation above 1000
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation + c.TotalReputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Location,
        u.EmailHash,
        Level + 1
    FROM Users u
    INNER JOIN UserScoreCTE c ON u.Id = c.UserId
    WHERE u.Reputation > 1000
    AND Level < 5 -- limiting the recursion to avoid deep nesting
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 4) -- counting only upvotes and offensive votes
    GROUP BY p.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames  -- aggregating badge names into a single string
    FROM Badges b
    WHERE b.Class = 1 -- only counting Gold badges
    GROUP BY b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.TotalReputation,
    CASE 
        WHEN ub.BadgeCount IS NOT NULL THEN ub.BadgeCount 
        ELSE 0 END AS GoldBadgeCount,
    ub.BadgeNames,
    COUNT(DISTINCT rp.Id) AS TotalPosts,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.VoteCount) AS TotalVotes
FROM Users u
LEFT JOIN UserScoreCTE us ON u.Id = us.UserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE u.Location IS NOT NULL -- filter to include users with a location
GROUP BY u.Id, u.DisplayName, us.TotalReputation, ub.BadgeCount, ub.BadgeNames
ORDER BY TotalVotes DESC, TotalPosts DESC, us.TotalReputation DESC
LIMIT 100; -- top 100 users based on the criteria
