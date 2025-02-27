WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        1 AS Level
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (1, 4, 10) -- Initial Title, Edit Title, Post Closed
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        Level + 1
    FROM PostHistory ph
    JOIN RecursivePostHistory rph ON ph.PostId = rph.PostId
    WHERE ph.CreationDate < rph.CreationDate
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS NumberOfClosures,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (1, 4) THEN ph.Id END) AS NumberOfTitleChanges,
    MAX(ph.CreationDate) AS LastHistoryChange,
    STRING_AGG(DISTINCT u.DisplayName, ', ') FILTER (WHERE ph.UserId IS NOT NULL) AS UsersInvolved,
    AVG(u.Reputation) AS AverageUserReputation,
    SUM(v.BountyAmount) AS TotalBountyAwarded
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Users u ON ph.UserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
WHERE 
    p.CreationDate >= '2023-01-01' -- consider only recent posts
GROUP BY 
    p.Id, p.Title, p.CreationDate
HAVING 
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) > 0 -- only posts that were closed
ORDER BY 
    TotalBountyAwarded DESC
LIMIT 10;
