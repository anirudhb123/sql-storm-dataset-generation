WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostVoteSummary AS (
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
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN PostHistoryTypeId = 11 THEN CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    COALESCE(up.UpVotes, 0) AS TotalUpVotes,
    COALESCE(dn.DownVotes, 0) AS TotalDownVotes,
    ph.LastClosedDate,
    ph.LastReopenedDate,
    u.DisplayName AS OwnerDisplayName,
    ub.BadgeCount,
    ub.BadgeNames AS UserBadges
FROM 
    Posts p
LEFT JOIN 
    PostVoteSummary up ON p.Id = up.PostId
LEFT JOIN 
    PostVoteSummary dn ON p.Id = dn.PostId
LEFT JOIN 
    PostHistorySummary ph ON p.Id = ph.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    AND p.Score > 10
    AND NOT EXISTS (
        SELECT 
            1 
        FROM 
            Comments c 
        WHERE 
            c.PostId = p.Id 
            AND c.Score < 0
    )
ORDER BY 
    p.Score DESC,
    p.CreationDate ASC
LIMIT 100;
