WITH RECURSIVE PostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL

    UNION ALL
    
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM Posts p
    JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
AggregatedUserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(u.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(u.DownVotes, 0)) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        MAX(u.Reputation) AS MaxReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopBadgedUsers AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
    HAVING COUNT(b.Id) > 5
),
UserPostStats AS (
    SELECT
        au.UserId,
        au.DisplayName,
        au.TotalUpVotes,
        au.TotalDownVotes,
        au.TotalPosts,
        au.TotalQuestions,
        au.TotalAnswers,
        tb.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY au.MaxReputation DESC) AS Rank
    FROM AggregatedUserStats au
    LEFT JOIN TopBadgedUsers tb ON au.UserId = tb.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.BadgeCount,
    ph.Title AS PostTitle,
    ph.Level AS PostLevel,
    COUNT(c.Id) AS CommentCount,
    AVG(v.Score) AS AverageVoteScore
FROM UserPostStats ups
LEFT JOIN Posts p ON ups.UserId = p.OwnerUserId
LEFT JOIN PostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE ups.BadgeCount IS NOT NULL 
AND ups.TotalPosts > 0
GROUP BY ups.UserId, ups.DisplayName, ups.TotalPosts, ups.TotalQuestions, ups.TotalAnswers, ups.BadgeCount, ph.Title, ph.Level
HAVING COUNT(c.Id) > 0
ORDER BY ups.MaxReputation DESC, ups.TotalPosts DESC;
