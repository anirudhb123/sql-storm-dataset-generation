WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),

PostEngagement AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  
        COUNT(DISTINCT p.Id) AS PostCount 
    FROM Posts p 
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Upvotes and Downvotes
    WHERE p.CreationDate > '2021-01-01' 
    GROUP BY p.OwnerUserId
),

CombinedStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        COALESCE(pe.CommentCount, 0) AS TotalComments,
        COALESCE(pe.UpVotes, 0) AS TotalUpVotes,
        pe.PostCount
    FROM UserBadgeStats ub
    LEFT JOIN PostEngagement pe ON ub.UserId = pe.OwnerUserId
)

SELECT 
    cs.UserId, 
    cs.DisplayName,
    cs.BadgeCount,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    cs.TotalComments,
    cs.TotalUpVotes,
    cs.PostCount,
    CASE 
        WHEN cs.BadgeCount IS NULL THEN 'Badge Count Unavailable'
        WHEN cs.TotalComments > 100 THEN 'Highly Engaged User'
        WHEN cs.GoldBadges > 0 THEN 'Elite Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM CombinedStats cs
WHERE cs.BadgeCount > 0 
OR cs.TotalComments > 50  
ORDER BY cs.TotalUpVotes DESC, cs.BadgeCount DESC
LIMIT 10;

-- Outer query fetching details from the main User table ensuring that some users with zero badges or upvotes are included as well
SELECT DISTINCT 
    u.Id AS UserId, 
    u.DisplayName, 
    u.Reputation,
    COALESCE(bads.BadgeCount, 0) AS BadgeCount,
    COALESCE(eng.TotalComments, 0) AS TotalComments
FROM Users u
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM Badges
    GROUP BY UserId
) AS bads ON u.Id = bads.UserId
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS TotalComments
    FROM Comments
    GROUP BY OwnerUserId
) AS eng ON u.Id = eng.OwnerUserId
WHERE u.Reputation > 1000
AND (bads.BadgeCount IS NULL OR bads.BadgeCount < 5) 
ORDER BY u.Reputation DESC
LIMIT 5;

This query consists of multiple CTEs (Common Table Expressions) to aggregate user badge statistics and post engagement metrics, handling NULL values and applying elaborate conditions. It also ranks the users based on their total upvotes, offering insight into user contributions, engaging further with outer joins to ensure a comprehensive result set showcasing both contributors' statistics and potential anomalies in data availability.
