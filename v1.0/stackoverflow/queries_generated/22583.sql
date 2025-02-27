WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        pm.TotalPosts,
        pm.TotalQuestions,
        pm.TotalAnswers,
        pm.TotalScore,
        pm.AvgViewCount,
        RANK() OVER (ORDER BY pm.TotalPosts DESC, pm.TotalScore DESC) AS UserRank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostMetrics pm ON u.Id = pm.OwnerUserId
),
ClosePostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON cr.Id = ph.Comment::int
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
)
SELECT 
    ru.Id AS UserId,
    ru.DisplayName,
    COALESCE(ru.TotalPosts, 0) AS TotalPosts,
    COALESCE(ru.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ru.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ru.TotalScore, 0) AS TotalScore,
    COALESCE(ru.AvgViewCount, 0) AS AvgViewCount,
    COALESCE(ru.UserRank, 0) AS UserRank,
    COALESCE(cr.CloseReasons, 'No Closed Posts') AS CloseReasons
FROM RankedUsers ru
LEFT JOIN ClosePostReasons cr ON cr.PostId IN (
    SELECT p.Id 
    FROM Posts p 
    WHERE p.OwnerUserId = ru.Id
)
WHERE ru.TotalPosts > 0
ORDER BY ru.UserRank;
