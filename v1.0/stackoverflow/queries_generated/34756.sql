WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        OwnerUserId,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only Questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    p.Title AS PostTitle,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    au.ActivePostCount,
    au.TotalViews
FROM 
    Users u
INNER JOIN 
    Posts p ON u.Id = p.OwnerUserId
INNER JOIN 
    PostStatistics ps ON ps.PostId = p.Id
INNER JOIN 
    ActiveUsers au ON u.Id = au.Id
WHERE 
    ps.Score > 0 
    AND ps.CommentCount > 5 
    AND au.ActivePostCount > 10
ORDER BY 
    au.TotalViews DESC,
    ps.Score DESC
LIMIT 50;


