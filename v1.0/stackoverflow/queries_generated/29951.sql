WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000  -- filter out low reputation users
    GROUP BY u.Id, u.DisplayName
), CloseReasons AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        COUNT(*) AS CloseReasonCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.UserId, ph.PostId
), UserActivity AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalScore,
        ups.TotalViews,
        ups.AvgScore,
        COALESCE(cr.CloseReasonCount, 0) AS ClosedPostCount
    FROM UserPostStats ups
    LEFT JOIN CloseReasons cr ON ups.UserId = cr.UserId
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    u.TotalViews,
    u.AvgScore,
    u.ClosedPostCount,
    CASE 
        WHEN u.TotalPosts > 50 THEN 'High Activity'
        WHEN u.TotalPosts > 20 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS PopularTags
FROM UserActivity u 
LEFT JOIN Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag(t) ON true
GROUP BY u.UserId, u.DisplayName, u.TotalPosts, u.TotalQuestions, u.TotalAnswers, u.TotalScore, u.TotalViews, u.AvgScore, u.ClosedPostCount
ORDER BY u.TotalScore DESC, u.TotalPosts DESC;
