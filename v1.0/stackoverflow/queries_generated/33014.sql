WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, CreationDate, Score, OwnerUserId, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    
    UNION ALL
    
    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, p.Score, p.OwnerUserId, r.Level + 1
    FROM Posts p
    JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MIN(ph.CreationDate) AS FirstOccurrence,
        MAX(ph.CreationDate) AS LastOccurrence,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
    p.CreationDate AS PostCreationDate,
    COALESCE(ph.LastOccurrence, 'No Changes') AS LastEditDate,
    COALESCE(pl.RelatedCount, 0) AS RelatedPostCount,
    COUNT(DISTINCT pc.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM Posts p
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN PostHistoryInfo ph ON p.Id = ph.PostId
LEFT JOIN PostLinks pl ON p.Id = pl.PostId
LEFT JOIN Comments pc ON p.Id = pc.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, u.DisplayName, ph.LastOccurrence, pl.RelatedCount
ORDER BY 
    PostCreationDate DESC,
    UpVotes - DownVotes DESC
LIMIT 50;
