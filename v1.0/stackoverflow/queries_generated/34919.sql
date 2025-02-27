WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title,
        ParentId,
        OwnerUserId,
        CreationDate,
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
        p.OwnerUserId,
        p.CreationDate,
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
VoteAggregates AS (
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
PostSummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        rph.Level
    FROM 
        Posts p
    LEFT JOIN 
        VoteAggregates v ON p.Id = v.PostId
    LEFT JOIN 
        UserBadges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        RecursivePostHierarchy rph ON p.Id = rph.Id
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.UpVotes,
    ps.DownVotes,
    ps.BadgeCount,
    (CASE 
        WHEN ps.BadgeCount > 5 THEN 'Veteran Contributor' 
        WHEN ps.BadgeCount BETWEEN 3 AND 5 THEN 'Regular Contributor'
        ELSE 'New Contributor' 
    END) AS ContributorStatus,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments c 
     WHERE 
        c.PostId = ps.Id 
     AND 
        c.CreationDate >= NOW() - INTERVAL '30 days'
    ) AS RecentCommentCount
FROM 
    PostSummary ps
WHERE 
    ps.Level = 0
ORDER BY 
    ps.UpVotes DESC, ps.CreationDate DESC
LIMIT 10;
