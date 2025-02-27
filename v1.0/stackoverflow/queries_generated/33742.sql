WITH RECURSIVE PostHierarchy AS (
    -- Base case: Start with all questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        1 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Question

    UNION ALL
    
    -- Recursive case: Get answers and build hierarchy
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        ph.Level + 1,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  -- Answer
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.OwnerUserId ORDER BY ph.CreationDate DESC) AS RecentRank
    FROM 
        PostHierarchy ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 DAYS'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.BadgeCount,
    ur.TotalBounty,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostCreationDate
FROM 
    UserReputation ur
LEFT JOIN 
    RecentPosts rp ON ur.UserId = rp.OwnerUserId
LEFT JOIN 
    Users u ON ur.UserId = u.Id
WHERE 
    rp.RecentRank = 1  -- Get the most recent post for each user
ORDER BY 
    ur.Reputation DESC,  -- Order by reputation descending
    rp.CreationDate DESC  -- Then by post creation date
LIMIT 50;  -- Limit to top 50 users
