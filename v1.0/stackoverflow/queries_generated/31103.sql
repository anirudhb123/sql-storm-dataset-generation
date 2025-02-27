WITH RecursivePostHierarchy AS (
    SELECT Id, ParentId, Title, Score, CreationDate, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL -- root level posts (questions)

    UNION ALL

    SELECT p.Id, p.ParentId, p.Title, p.Score, p.CreationDate, r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),

TopUsers AS (
    SELECT Id, DisplayName, Reputation, 
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation >= 5000 -- filtering high-reputation users
),

PopularPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName AS Owner
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '30 days' 
    ORDER BY p.Score DESC
    LIMIT 10
),

PostHistories AS (
    SELECT ph.PostId, 
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
           COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditCount,
           MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),

PostSummary AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ViewCount,
           COALESCE(ph.CloseReopenCount, 0) AS CloseReopenCount,
           COALESCE(ph.SuggestedEditCount, 0) AS SuggestedEditCount,
           ph.LastEditDate,
           TOPU.Reputation AS TopUserReputation
    FROM Posts p
    LEFT JOIN PostHistories ph ON p.Id = ph.PostId
    LEFT JOIN TopUsers TOPU ON p.OwnerUserId = TOPU.Id
)

SELECT 
    RPH.Level,
    PS.Title,
    PS.ViewCount,
    PS.CloseReopenCount,
    PS.SuggestedEditCount,
    PS.LastEditDate,
    PS.TopUserReputation
FROM PostSummary PS
JOIN RecursivePostHierarchy RPH ON PS.PostId = RPH.Id
WHERE PS.TopUserReputation IS NOT NULL
ORDER BY RPH.Level, PS.ViewCount DESC
LIMIT 20;
