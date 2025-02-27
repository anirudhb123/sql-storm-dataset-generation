WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Start with top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        vt.Name AS VoteType,
        RANK() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days' -- Filter for recent votes
)
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    ph.Level AS HierarchyLevel,
    ur.DisplayName AS PostOwner,
    ur.Reputation AS OwnerReputation,
    ur.PostsCount AS TotalPostsByOwner,
    COALESCE(rv.VoteType, 'No Votes') AS RecentVoteType,
    CASE 
        WHEN ph.ParentId IS NULL THEN 'Top Level'
        ELSE 'Child Post'
    END AS PostHierarchyStatus
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    UserReputation ur ON p.OwnerUserId = ur.UserId
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId AND rv.VoteRank = 1
WHERE 
    (ur.Reputation > 100 OR ur.Reputation IS NULL) -- Condition including NULL logic
ORDER BY 
    p.Title, ph.Level DESC;
