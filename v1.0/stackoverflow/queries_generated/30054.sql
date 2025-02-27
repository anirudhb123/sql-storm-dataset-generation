WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        CAST(u.CreationDate AS DATE) AS CreationDate,
        1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        CAST(u.CreationDate AS DATE),
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON ur.Reputation < u.Reputation
    WHERE ur.Level < 5
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        MAX(ph.CreationDate) AS LastModified
    FROM PostHistory ph
    GROUP BY ph.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ut.QuestionCount,
    ut.AnswerCount,
    COUNT(DISTINCT tq.PostId) AS TopQuestionCount,
    COALESCE(SUM(pha.HistoryCount), 0) AS TotalPostHistories,
    COALESCE(SUM(pha.CloseCount), 0) AS TotalCloseHistories
FROM UserReputation ur
LEFT JOIN UserPostStats ut ON ur.Id = ut.UserId
LEFT JOIN TopQuestions tq ON tq.Rank <= 3
LEFT JOIN PostHistoryAggregates pha ON pha.PostId IN (
    SELECT p.Id 
    FROM Posts p 
    WHERE p.OwnerUserId = ur.Id
)
WHERE ur.Level <= 3
GROUP BY ur.DisplayName, ur.Reputation, ut.QuestionCount, ut.AnswerCount
ORDER BY ur.Reputation DESC
LIMIT 10;
