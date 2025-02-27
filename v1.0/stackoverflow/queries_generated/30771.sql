WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
RecentTags AS (
    SELECT 
        Tags,
        ROW_NUMBER() OVER (PARTITION BY Tags ORDER BY CreationDate DESC) AS rn
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(rph.Level, 0) AS PostLevel,
        CONCAT(u.DisplayName, ' (', u.Reputation, ')') AS PostedBy
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.ViewCount > 100 AND 
        p.CreationDate >= NOW() - INTERVAL '180 days'
    ORDER BY 
        p.ViewCount DESC
)
SELECT 
    fp.Title AS PostTitle,
    fp.ViewCount,
    fp.CreationDate,
    fp.PostLevel,
    fp.PostedBy,
    COALESCE(rt.Tags, 'No Tags') AS RecentTags,
    ur.TotalPosts,
    ur.TotalBadges
FROM 
    FilteredPosts fp
LEFT JOIN 
    RecentTags rt ON rt.rn = 1
LEFT JOIN 
    UserReputation ur ON fp.OwnerUserId = ur.Id
ORDER BY 
    fp.ViewCount DESC, 
    fp.CreationDate DESC
LIMIT 50;
