-- Performance Benchmarking Query
WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        CAST(p.Title AS VARCHAR(300)) AS PostTitle,
        1 AS Level,
        p.CreationDate
    FROM Posts p
    WHERE p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        CAST(r.PostTitle || ' -> ' || p.Title AS VARCHAR(300)) AS PostTitle,
        Level + 1,
        p.CreationDate
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AggregatedScores AS (
    SELECT 
        p.OwnerUserId,
        SUM(c.Score) AS TotalCommentScore,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(a.TotalCommentScore, 0) AS TotalCommentScore,
        COALESCE(a.CommentCount, 0) AS CommentCount
    FROM Users u
    LEFT JOIN AggregatedScores a ON u.Id = a.OwnerUserId
    WHERE u.Reputation > 100 -- Filter users with reputation > 100
    ORDER BY a.TotalCommentScore DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    t.DisplayName AS TopUserName,
    t.Reputation AS TopUserReputation,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    COALESCE(phs.CloseCount, 0) AS TotalCloses,
    r.PostTitle,
    r.Level AS PostLevel,
    r.CreationDate,
    r.PostId
FROM TopUsers t
JOIN Posts p ON p.OwnerUserId = t.UserId
JOIN RecursivePostHierarchy r ON p.Id = r.PostId
LEFT JOIN PostHistorySummary phs ON r.PostId = phs.PostId
WHERE r.Level <= 2 -- consider only top 2 levels
ORDER BY t.TotalCommentScore DESC, r.CreationDate DESC;
