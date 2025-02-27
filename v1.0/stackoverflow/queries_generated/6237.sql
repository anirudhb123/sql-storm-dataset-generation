WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS QuestionsWithAcceptedAnswers
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, '>')::int[])
    GROUP BY t.TagName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.Score > 0
    GROUP BY p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpVotes,
    us.TotalDownVotes,
    ts.TagName,
    ts.PostCount,
    ts.QuestionsWithAcceptedAnswers,
    phs.EditCount,
    phs.LastEditDate
FROM UserStatistics us
JOIN TagStatistics ts ON us.TotalPosts > 0
JOIN PostHistoryStats phs ON us.TotalPosts = phs.PostId
ORDER BY us.TotalPosts DESC, ts.PostCount DESC
LIMIT 100;
