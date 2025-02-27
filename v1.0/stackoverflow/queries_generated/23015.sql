WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        CASE 
            WHEN u.Reputation > 1000 THEN 'Experienced' 
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate' 
            ELSE 'Novice' 
        END AS ReputationLevel
    FROM Users u
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS RecentActivityCount
    FROM Posts p
    WHERE p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
)
SELECT 
    u.DisplayName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ps.TotalPosts,
    ps.Questions,
    ps.Answers,
    rsp.RecentActivityCount,
    ur.Reputation,
    ur.ReputationLevel,
    COALESCE(NULLIF(ur.CreationDate, ur.LastAccessDate), 'N/A') AS LastActiveDate,
    CASE 
        WHEN ur.LastAccessDate IS NULL THEN 'Inactive'
        WHEN ur.LastAccessDate < NOW() - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active' 
    END AS UserActivityStatus
FROM UserBadgeStats ub
JOIN PostStats ps ON ub.UserId = ps.OwnerUserId
JOIN UserReputation ur ON ub.UserId = ur.Id
LEFT JOIN RecentPostActivity rsp ON ub.UserId = rsp.OwnerUserId
ORDER BY ub.TotalBadges DESC, ur.Reputation DESC
LIMIT 100;
This SQL query performs performance benchmarking across several dimensions such as user badges, post statistics, user reputation, and recent activity. It uses Common Table Expressions (CTEs) for modularity, joins, and sophisticated conditional logic to derive user activity levels and badge statistics, making it suitable for complex analytical scenarios.
