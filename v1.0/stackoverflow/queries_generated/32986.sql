WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpVotes, 
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownVotes 
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 19 THEN 1 END) AS ProtectedVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    r.Level AS PostHierarchyLevel,
    u.DisplayName AS OwnerDisplayName,
    u.TotalBounty,
    u.TotalUpVotes,
    u.TotalDownVotes,
    ph.CloseVotes,
    ph.ProtectedVotes,
    ph.DeletionVotes,
    ph.ReopenVotes,
    t.TagName,
    t.PostCount
FROM Posts p
LEFT JOIN RecursivePostHierarchy r ON p.Id = r.Id
LEFT JOIN UserScoreSummary u ON p.OwnerUserId = u.UserId
LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId
LEFT JOIN TagUsage t ON t.PostCount > 5
WHERE p.ViewCount > 100
ORDER BY p.CreationDate DESC, u.TotalUpVotes DESC
LIMIT 50;
