WITH RECURSIVE PostsHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level,
        p.OwnerUserId
    FROM Posts p
    WHERE p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1,
        p.OwnerUserId
    FROM Posts p
    INNER JOIN PostsHierarchy ph ON p.ParentId = ph.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN pht.Name = 'Edit Title' THEN ph.CreationDate END) AS FirstEditDate,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS CloseDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseActions
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)

SELECT 
    p.Title,
    ph.PostId,
    ph.Level,
    ue.DisplayName,
    ue.PostCount,
    ue.UpVotesCount,
    ue.DownVotesCount,
    uh.BadgeCount,
    COALESCE(phd.FirstEditDate, 'Never Edited') AS FirstEditDate,
    COALESCE(phd.CloseDate, 'Not Closed') AS CloseDate,
    phd.CloseActions
FROM PostsHierarchy ph
JOIN UserEngagement ue ON ph.OwnerUserId = ue.UserId
LEFT JOIN PostHistoryDetails phd ON ph.PostId = phd.PostId
WHERE ue.PostCount > 5
ORDER BY ph.Level DESC, ue.PostCount DESC;
