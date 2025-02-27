WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
PostStats AS (
    SELECT 
        ps.OwnerUserId,
        COUNT(ps.Id) AS TotalPosts,
        SUM(ps.ViewCount) AS TotalViews,
        AVG(ps.ViewCount) AS AvgViews,
        MAX(ps.CreationDate) AS LastPostDate
    FROM 
        RecursivePosts ps 
    GROUP BY 
        ps.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        ps.AvgViews,
        ps.LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.TotalPosts,
    ur.TotalViews,
    ur.AvgViews,
    ur.LastPostDate,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'High' 
        WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Medium' 
        ELSE 'Low' 
    END AS Reputation_Category,
    COUNT(DISTINCT DISTINCT bh.Id) AS BadgeCount,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames,
    (
        SELECT 
            COUNT(DISTINCT v.Id)
        FROM 
            Votes v
        JOIN 
            Posts p ON v.PostId = p.Id
        WHERE 
            p.OwnerUserId = ur.UserId
    ) AS TotalVotes
FROM 
    UserReputation ur
LEFT JOIN 
    Badges b ON ur.UserId = b.UserId
LEFT JOIN 
    Badges bh ON bh.Class = 1 -- Only Gold badges
GROUP BY 
    ur.UserId, ur.Reputation, ur.TotalPosts, ur.TotalViews, ur.AvgViews, ur.LastPostDate
ORDER BY 
    ur.Reputation DESC, ur.TotalPosts DESC
LIMIT 50;
