WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(DISTINCT ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId, ph.CreationDate
),
AggregatePostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(ph.EditCount), 0) AS TotalEdits
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistories ph ON p.Id = ph.PostId
    GROUP BY p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Level,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    us.UpVotes,
    us.DownVotes,
    ap.CommentCount,
    ap.TotalEdits
FROM RecursivePostHierarchy r
JOIN Users u ON r.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN UserScores us ON us.UserId = u.Id
LEFT JOIN AggregatePostInfo ap ON r.PostId = ap.PostId
WHERE u.Reputation > 50
ORDER BY r.Level, r.CreationDate DESC;
