WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(v.VoteTypeId IN (2, 3)) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS FirstCloseDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph 
    WHERE ph.PostHistoryTypeId = 10
),
TopUsers AS (
    SELECT 
        ua.UserId, 
        ua.DisplayName, 
        ua.PostCount, 
        ua.AnswerCount, 
        ua.QuestionCount, 
        ua.TotalVotes,
        ROW_NUMBER() OVER (ORDER BY ua.PostCount DESC) AS Rank
    FROM UserActivity ua
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(cp.FirstCloseDate, 'No Closure') AS ClosureDate,
        COALESCE(cp.CloseReason, 'N/A') AS CloseReason,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN ClosedPostHistory cp ON p.Id = cp.PostId
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    pu.PostCount,
    pu.AnswerCount,
    pu.QuestionCount,
    pu.TotalVotes,
    ps.PostId,
    ps.Title,
    ps.ClosureDate,
    ps.CloseReason,
    ps.CommentCount
FROM TopUsers pu
CROSS JOIN PostStats ps
WHERE pu.Rank <= 10 AND ps.CommentCount > 0
ORDER BY pu.DisplayName, ps.Title;
