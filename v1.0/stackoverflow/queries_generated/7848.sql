WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryChangeDate
    FROM PostHistory ph
    GROUP BY ph.UserId
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.UpvotedPosts,
        ups.AverageScore,
        ups.LastPostDate,
        phs.HistoryCount,
        phs.LastHistoryChangeDate
    FROM UserPostStatistics ups
    LEFT JOIN PostHistorySummary phs ON ups.UserId = phs.UserId
    ORDER BY ups.PostCount DESC
    LIMIT 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpvotedPosts,
    tu.AverageScore,
    tu.LastPostDate,
    COALESCE(tu.HistoryCount, 0) AS HistoryCount,
    COALESCE(tu.LastHistoryChangeDate, 'No Changes') AS LastHistoryChangeDate
FROM TopUsers tu
JOIN Badges b ON tu.UserId = b.UserId
WHERE b.Class = 1
ORDER BY tu.AverageScore DESC;
