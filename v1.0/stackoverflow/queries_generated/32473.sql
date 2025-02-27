WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- starting point for post hierarchy

    UNION ALL

    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId  -- recursive join to find child posts

),
PostStatistics AS (
    SELECT
        ph.PostId,
        ph.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        MAX(ph.Level) AS MaxLevel
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN Comments c ON ph.PostId = c.PostId
    LEFT JOIN Votes v ON ph.PostId = v.PostId
    GROUP BY
        ph.PostId,
        ph.Title
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'  -- filter for recent history
)

SELECT
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.BadgeCount,
    ub.BadgeNames,
    rph.CreationDate AS RecentChangeDate,
    rph.Comment AS RecentChangeComment,
    rph.PostHistoryTypeId AS RecentChangeType
FROM 
    PostStatistics ps
LEFT JOIN UserBadges ub ON ps.PostId = ub.UserId  -- Assume correlation on UserId for demonstration
LEFT JOIN RecentPostHistory rph ON ps.PostId = rph.PostId AND rph.rn = 1  -- join to get the latest history change
WHERE 
    ps.MaxLevel > 0  -- filter to show only posts that are part of a hierarchy
ORDER BY 
    ps.UpVotes DESC,
    ps.CommentCount DESC;
