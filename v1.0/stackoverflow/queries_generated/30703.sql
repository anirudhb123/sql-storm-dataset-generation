WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AggregatedVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Date AS EarnedDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS Rank
    FROM 
        Users u
    INNER JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date > NOW() - INTERVAL '1 year'
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(v.UpVotes, 0) AS TotalUpVotes,
    COALESCE(v.DownVotes, 0) AS TotalDownVotes,
    r.UserId,
    r.BadgeName,
    r.EarnedDate,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    ph.Level AS PostLevel
FROM 
    Posts p
LEFT JOIN 
    AggregatedVotes v ON p.Id = v.PostId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId 
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecentBadges r ON u.Id = r.UserId AND r.Rank = 1
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '30 days'
    AND (p.ViewCount > 100 OR p.Score > 10)
GROUP BY 
    p.Id, v.UpVotes, v.DownVotes, r.UserId, r.BadgeName, r.EarnedDate, ph.Level
ORDER BY 
    p.CreationDate DESC, TotalUpVotes DESC
LIMIT 50;
