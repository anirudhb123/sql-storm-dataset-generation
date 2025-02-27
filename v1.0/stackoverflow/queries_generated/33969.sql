WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
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
        p.Score,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVotingStats AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
LatestPostEdit AS (
    SELECT 
        p.Id AS PostId,
        p.LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastEditDate DESC) AS EditRank
    FROM 
        Posts p
),
UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(vs.TotalVotes, 0) AS TotalVotes,
    ph.Level AS PostLevel,
    e.LastEditDate,
    ub.BadgeCount,
    CASE 
        WHEN e.LastEditDate IS NOT NULL THEN 'Edited' 
        ELSE 'Not Edited' 
    END AS EditStatus
FROM 
    Posts p
LEFT JOIN 
    PostVotingStats vs ON p.Id = vs.PostId
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    LatestPostEdit e ON p.Id = e.PostId AND e.EditRank = 1
LEFT JOIN 
    UserBadgeCount ub ON p.OwnerUserId = ub.UserId
WHERE 
    p.ViewCount > 100
ORDER BY 
    p.Score DESC, 
    p.Title ASC;

This SQL query showcases a combination of recursive CTEs, multiple CTEs for aggregating data, outer joins, window functions, and conditional case expressions. It retrieves a detailed overview of posts that have a view count greater than 100, including voting statistics, hierarchical post information, edit status, and user badge counts while emphasizing performance aspects with potential optimization opportunities.
