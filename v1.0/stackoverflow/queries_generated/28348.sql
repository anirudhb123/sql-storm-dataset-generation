WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AvgScore
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    GROUP BY t.TagName
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS FirstTitleEdit,
        MAX(CASE WHEN ph.PostHistoryTypeId = 2 THEN ph.CreationDate END) AS FirstBodyEdit,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS CloseReopenDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT 
    t.TagName,
    ts.PostCount AS TotalPostsWithTag,
    ts.QuestionCount AS QuestionsWithTag,
    ts.AnswerCount AS AnswersWithTag,
    ts.AvgViewCount AS AvgPostViewCount,
    ts.AvgScore AS AvgPostScore,
    ua.DisplayName AS TopUser,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalBadges,
    ua.AccountCreationDate,
    phs.FirstTitleEdit,
    phs.FirstBodyEdit,
    phs.CloseReopenDate
FROM TagStatistics ts
JOIN UserActivity ua ON ua.TotalPosts = (SELECT MAX(TotalPosts) FROM UserActivity)
JOIN PostHistorySummary phs ON phs.PostId IN 
    (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
JOIN Tags t ON t.TagName = ts.TagName
ORDER BY ts.AvgViewCount DESC
LIMIT 10;
