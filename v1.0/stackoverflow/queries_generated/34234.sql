WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
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
        p.CreationDate,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ur.TotalBounty, 0) AS TotalBounty,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.HighestBadgeClass, 0) AS HighestBadgeClass,
    p.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    r.Level AS PostHierarchyLevel
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostStatistics ps ON p.Id = ps.PostId
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId
WHERE 
    (u.Reputation > 1000 OR (ur.TotalBounty > 0 AND ub.BadgeCount >= 2))
    AND r.Level IS NULL  -- Only considering top-level posts
ORDER BY 
    u.Reputation DESC, 
    p.CreationDate DESC
LIMIT 50;
