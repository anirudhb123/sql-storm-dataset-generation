WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Select only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
), PostVotes AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Users u
    INNER JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1  -- Gold badges
    GROUP BY 
        u.Id
), PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(b.BadgeCount, 0) AS UserGoldBadgeCount,
    ph.LastClosedDate,
    ph.HistoryCount,
    STRING_AGG(DISTINCT CONCAT('Level ', rp.Level, ': ', rp.Title), '; ') AS PostHierarchy
FROM 
    RecursivePostHierarchy rp
LEFT JOIN 
    PostVotes v ON rp.PostId = v.PostId
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistoryAggregated ph ON rp.PostId = ph.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, v.UpVotes, v.DownVotes, b.BadgeCount, ph.LastClosedDate, ph.HistoryCount
ORDER BY 
    UpVotes DESC, rp.CreationDate DESC
LIMIT 100;
