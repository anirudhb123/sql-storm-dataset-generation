WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
VoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
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
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT ph.Id) AS ChildCount,
        MAX(ph.Level) AS MaxHierarchyLevel
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    WHERE 
        ph.PostId IS NOT NULL
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(bs.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bs.BadgeNames, 'No Badges') AS UserBadgeNames,
    COALESCE(cp.ChildCount, 0) AS ChildCount,
    COALESCE(cp.MaxHierarchyLevel, 0) AS MaxHierarchyLevel
FROM 
    Posts p
LEFT JOIN 
    VoteStats vs ON p.Id = vs.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges bs ON u.Id = bs.UserId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    p.PostTypeId = 1 
    AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Only include posts created in the last year
ORDER BY 
    p.CreationDate DESC
OPTION (MAXRECURSION 100);
