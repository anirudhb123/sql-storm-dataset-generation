WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.Id
),
UserReputationHistory AS (
    SELECT 
        UserId,
        SUM(Reputation) AS TotalReputation,
        COUNT(*) AS PostCount,
        MAX(LastAccessDate) AS LastActive
    FROM 
        Users
    INNER JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        UserId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    uph.Level AS PostLevel,
    COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
    urh.TotalReputation,
    urh.PostCount,
    urh.LastActive
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHierarchy uph ON p.Id = uph.Id
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId
LEFT JOIN 
    UserReputationHistory urh ON u.Id = urh.UserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
AND 
    (uph.Level = 0 OR urh.PostCount > 10)
ORDER BY 
    Urh.TotalReputation DESC, 
    p.CreationDate DESC
LIMIT 100;
