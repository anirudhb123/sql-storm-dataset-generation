
WITH RECURSIVE PostHierarchy AS (
    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, 1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL  

    UNION ALL 

    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),

PostVoteInfo AS (
    SELECT p.Id AS PostId, 
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes, 
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),

RecentClosedPosts AS (
    SELECT p.Id, p.Title, ph.Level, p.CreationDate, p.ParentId, 
           COALESCE(pvi.UpVotes, 0) AS UpVotes, 
           COALESCE(pvi.DownVotes, 0) AS DownVotes
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.Id = ph.Id
    LEFT JOIN PostVoteInfo pvi ON p.Id = pvi.PostId
    WHERE p.ClosedDate IS NOT NULL 
    AND p.CreationDate >= DATEADD(month, -1, '2024-10-01 12:34:56')
),

BadgesPerUser AS (
    SELECT u.Id AS UserId, 
           COUNT(b.Id) AS BadgeCount,
           LISTAGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    rcp.Title AS ClosedPostTitle,
    rcp.CreationDate AS ClosedDate,
    rcp.UpVotes,
    rcp.DownVotes,
    bp.BadgeCount,
    bp.BadgeNames,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = rcp.Id) AS CommentCount
FROM RecentClosedPosts rcp
LEFT JOIN BadgesPerUser bp ON rcp.ParentId = bp.UserId
ORDER BY rcp.CreationDate DESC
LIMIT 10;
