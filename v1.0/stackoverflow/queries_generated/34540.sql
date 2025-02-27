WITH RecursiveUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
ClosedPostsStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPostCount,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Close action
    GROUP BY ph.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(up.TotalPosts, 0) AS TotalPosts,
    COALESCE(up.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(up.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ub.TotalBadges, 0) AS TotalBadges,
    COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
    COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(cp.FirstClosedDate, 'N/A') AS FirstClosedDate
FROM Users u
LEFT JOIN RecursiveUserPosts up ON u.Id = up.UserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN ClosedPostsStats cp ON u.Id = cp.UserId
WHERE u.Reputation > 100
ORDER BY u.Reputation DESC, TotalPosts DESC;

