-- Performance benchmarking SQL query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        AVG(p.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
)
SELECT 
    us.UserId, 
    us.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVoteCount,
    us.DownVoteCount,
    us.AverageScore,
    phs.HistoryCount,
    phs.LastEditDate
FROM UserStats us
JOIN PostHistoryStats phs ON us.PostCount > 0 AND us.PostCount = phs.PostId
ORDER BY us.PostCount DESC;
