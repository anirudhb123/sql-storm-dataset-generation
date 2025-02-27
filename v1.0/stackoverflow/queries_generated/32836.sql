WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        ParentId, 
        Title, 
        CreationDate,
        OwnerUserId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL -- Start with top-level posts (questions)
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.ParentId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
        INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentPostEdit AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastEditDate
    FROM 
        PostHistory
    GROUP BY 
        PostId
),
UserBadgeCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(r.LastEditDate, 'N/A') AS LastEditDate,
        u.Reputation,
        bc.BadgeCount
    FROM 
        Posts p
        LEFT JOIN PostVoteSummary v ON p.Id = v.PostId
        LEFT JOIN RecentPostEdit r ON p.Id = r.PostId
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN UserBadgeCount bc ON u.Id = bc.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    r.Level,
    r.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.LastEditDate,
    fp.Reputation,
    fp.BadgeCount,
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive Engagement'
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM 
    RecursivePostHierarchy r
JOIN 
    FilteredPosts fp ON r.Id = fp.Id
ORDER BY 
    r.Level, 
    fp.ViewCount DESC;
