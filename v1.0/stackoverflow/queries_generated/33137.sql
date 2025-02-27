WITH RecursivePostHierarchy AS (
    SELECT Id AS PostId, ParentId, Title, CreatorId = OwnerUserId, Level = 0
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.ParentId, p.Title, p.OwnerUserId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
TopUsers AS (
    SELECT u.Id AS UserId, u.DisplayName, SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(v.BountyAmount) > 0
),
PostHistorySummary AS (
    SELECT ph.PostId, COUNT(*) AS EditCount, MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags edits
    GROUP BY ph.PostId
),
RecentPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, COALESCE(posts.EditCount, 0) AS EditCount
    FROM Posts p
    LEFT JOIN PostHistorySummary posts ON p.Id = posts.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT r.PostId) AS TotalPosts,
    SUM(r.Level) AS TotalReplyDepth,
    COALESCE(SUM(tu.TotalBounty), 0) AS TotalBounty,
    MAX(r.Title) AS LastPostTitle,
    MAX(r.CreationDate) AS LastPostDate,
    MAX(ph.LastEditDate) AS LastEditedPostDate,
    SUM(CASE WHEN rp.EditCount > 0 THEN 1 ELSE 0 END) AS PostsWithEdits
FROM Users u
INNER JOIN RecursivePostHierarchy r ON u.Id = r.CreatorId
LEFT JOIN TopUsers tu ON u.Id = tu.UserId
LEFT JOIN PostHistorySummary ph ON r.PostId = ph.PostId
LEFT JOIN RecentPosts rp ON r.PostId = rp.Id
GROUP BY u.Id, u.DisplayName
HAVING COUNT(DISTINCT r.PostId) > 5
ORDER BY TotalBounty DESC, TotalPosts DESC
LIMIT 10;
