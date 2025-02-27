WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        0 AS Level
    FROM Users
    WHERE Reputation > 1000  -- Base case: Users with reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1 
    FROM Users u
    INNER JOIN UserReputation ur ON u.Reputation > ur.Reputation
    WHERE u.Reputation <= 10000   -- Stop the recursion at a reputation of 10,000
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        MAX(p.Score) AS MaxScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ur.Reputation,
    ps.TotalPosts,
    ps.Questions,
    ps.Answers,
    ps.MaxScore,
    ps.TotalViews,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN ub.BadgeCount > 10 THEN 'Active Contributor'
        WHEN ur.Reputation > 5000 THEN 'Veteran'
        ELSE 'New Contributor' 
    END AS ContributorLevel
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE ur.Level > 0
  AND (ps.TotalPosts > 5 OR ub.BadgeCount > 0)  -- Filter for users with significant engagement
ORDER BY ur.Reputation DESC, ps.TotalViews DESC
LIMIT 100;
