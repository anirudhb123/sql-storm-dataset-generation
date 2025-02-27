WITH RecursivePostHierarchy AS (
    -- CTE to recursively get answers related to questions
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.Score,
        p.CreationDate,
        Level + 1
    FROM Posts p
    JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
    WHERE p.PostTypeId = 2  -- Answers only
),
UserReputation AS (
    -- CTE to calculate user reputation scores and total answers
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    -- CTE to get the top users by reputation
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
    WHERE Reputation > 1000 -- filtering for high reputation users
),
RecentPostHistory AS (
    -- CTE to aggregate recent post history
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY p.Id
),
PopularQuestions AS (
    -- CTE to find popular questions based on score
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE p.PostTypeId = 1  -- Questions only
    GROUP BY p.Id
)

-- Main query to combine all CTEs and extract the final report
SELECT 
    pq.Title AS QuestionTitle,
    pu.DisplayName AS TopUser,
    pu.Reputation AS UserReputation,
    pq.Score AS QuestionScore,
    pq.ViewCount AS QuestionViews,
    pgh.HistoryTypes AS RecentHistory,
    pgh.LastEditDate AS LastEdit
FROM PopularQuestions pq
JOIN TopUsers pu ON pq.Rank = 1 -- Should join to a specific user, adjust as necessary
LEFT JOIN RecentPostHistory pgh ON pq.Id = pgh.PostId
WHERE pq.AnswerCount > 5 -- filtering for questions with a great number of answers
ORDER BY pq.Score DESC, pu.Reputation DESC;
