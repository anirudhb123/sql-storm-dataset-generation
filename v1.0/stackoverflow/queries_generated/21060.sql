WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AvgPostScore,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalAnswers DESC) AS Rank
    FROM UserPostStats
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT 
    ru.Rank,
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.AvgPostScore,
    COALESCE(bc.GoldBadges, 0) AS GoldBadges,
    COALESCE(bc.SilverBadges, 0) AS SilverBadges,
    COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(cpr.CloseReasons, 'No closures') AS CloseReasons
FROM RankedUsers ru
LEFT JOIN UserBadgeCounts bc ON ru.UserId = bc.UserId
LEFT JOIN ClosedPostReasons cpr ON cpr.PostId IN (
    SELECT Id 
    FROM Posts 
    WHERE OwnerUserId = ru.UserId AND ClosedDate IS NOT NULL
)
WHERE ru.TotalPosts > 0
  AND ru.AvgPostScore IS NOT NULL
ORDER BY ru.Rank
LIMIT 10;

-- This query provides a performance benchmark by aggregating user stats, 
-- their badge counts, and any closure reasons for their posts.
-- It uses CTEs for organization, along with window functions for rankings, 
-- and incorporates outer joins allowing for NULLs in various scenarios.
-- The use of COALESCE handles potential NULL values effectively.
