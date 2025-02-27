mysql
WITH UserVotes AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM Votes
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        SUM(ViewCount) as TotalViews,
        AVG(Score) as AvgScore,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM Posts
    GROUP BY OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        ph.UserId,
        p.OwnerUserId,
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostHistoryType,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id,
    (SELECT @rn := 0, @prevOwnerUserId := NULL) AS vars
    WHERE ph.CreationDate >= now() - INTERVAL 30 DAY
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(uv.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(uv.TotalDownvotes, 0) AS TotalDownvotes,
    ps.TotalViews,
    ps.AvgScore,
    ps.QuestionCount,
    ps.AnswerCount,
    RPH.PostId,
    RPH.PostHistoryType,
    RPH.CreationDate
FROM Users u
LEFT JOIN UserVotes uv ON u.Id = uv.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentPostHistory RPH ON u.Id = RPH.OwnerUserId AND RPH.rn = 1
WHERE 
    (ps.QuestionCount > 0 OR ps.AnswerCount > 0)
    AND (u.Reputation IS NOT NULL AND u.Reputation > 100)
ORDER BY 
    ps.TotalViews DESC,
    ps.AvgScore DESC,
    u.DisplayName;
