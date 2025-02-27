WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId, 
        ParentId,
        Title,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId, 
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastCloseDate,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    r.PostId,
    r.Title,
    r.Level,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(phs.LastCloseDate, 'Never') AS LastCloseDate,
    phs.BadgeCount
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    VoteStatistics vs ON r.PostId = vs.PostId
LEFT JOIN 
    PostHistorySummary phs ON r.PostId = phs.PostId
ORDER BY 
    r.Level, r.PostId;
