WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0
),
PostVoteSummary AS (
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
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS ReasonsClosed
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.Level,
    up.DisplayName AS Owner,
    up.Reputation,
    up.Rank,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    COALESCE(cl.ReasonsClosed, 0) AS ReasonsClosed,
    CASE 
        WHEN cl.ReasonsClosed > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RecursivePostHierarchy rp
LEFT JOIN 
    Users up ON rp.Id = up.Id
LEFT JOIN 
    PostVoteSummary ps ON rp.Id = ps.PostId
LEFT JOIN 
    ClosedPosts cl ON rp.Id = cl.PostId
WHERE 
    up.Reputation IS NOT NULL
ORDER BY 
    rp.Level, up.Reputation DESC
LIMIT 100;
