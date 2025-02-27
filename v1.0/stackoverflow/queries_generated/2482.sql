WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate
    FROM Users
    WHERE Reputation > 1000
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionsCreated,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswersCreated,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.PostId
),
CommentsStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.QuestionsCreated,
    ps.AnswersCreated,
    ps.TotalViews,
    ps.TotalScore,
    COALESCE(rph.EditCount, 0) AS TotalEdits,
    rph.LastEditDate,
    COALESCE(cs.TotalComments, 0) AS CommentCount,
    CASE 
        WHEN ps.TotalScore > 0 THEN 'Positive'
        WHEN ps.TotalScore < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory
FROM UserReputation u
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentPostHistory rph ON rph.PostId IN (
    SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id
)
LEFT JOIN CommentsStats cs ON cs.PostId IN (
    SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id
)
WHERE u.CreationDate > '2022-01-01'
ORDER BY u.Reputation DESC, ps.TotalScore DESC;
