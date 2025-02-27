WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    u.BadgeCount,
    u.BadgeNames,
    pv.UpVotes,
    pv.DownVotes,
    pv.NetVotes
FROM 
    PostHierarchy ph
LEFT JOIN 
    UserBadges u ON ph.PostId IN (SELECT DISTINCT ParentId FROM Posts WHERE ParentId IS NOT NULL)
LEFT JOIN 
    PostWithVotes pv ON ph.PostId = pv.PostId
WHERE 
    pv.NetVotes IS NOT NULL
ORDER BY 
    pv.NetVotes DESC,
    ph.Level ASC
LIMIT 100;

