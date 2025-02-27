WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM Posts p
    JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
RecentPostHistory AS (
    SELECT 
        pp.PostId,
        pp.RevisionGUID,
        pp.CreationDate,
        ph.Name AS HistoryTypeName,
        ROW_NUMBER() OVER (PARTITION BY pp.PostId ORDER BY pp.CreationDate DESC) AS rn
    FROM PostHistory pp
    JOIN PostHistoryTypes ph ON pp.PostHistoryTypeId = ph.Id
    WHERE pp.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    ph.Level AS HierarchyLevel,
    rh.RevisionGUID,
    rh.CreationDate AS LastHistoryChange
FROM Posts p
LEFT JOIN PostVoteSummary vs ON p.Id = vs.PostId
LEFT JOIN PostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN RecentPostHistory rh ON p.Id = rh.PostId AND rh.rn = 1
WHERE 
    p.CreationDate >= NOW() - INTERVAL '90 days' AND 
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 5
ORDER BY p.Title
OPTION (MAXRECURSION 100);

