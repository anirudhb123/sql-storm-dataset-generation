WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.PostTypeId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.PostTypeId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

VoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
    REPLACE((SELECT STRING_AGG(t.TagName, ', ') 
              FROM Tags t 
              WHERE t.Id IN (
                  SELECT unnest(string_to_array(SUBSTR(p.Tags, 2, LENGTH(p.Tags)-2), '>'))::int) 
                  )
             ), ',', ', ') AS Tags,
    up.UserId AS TopUserId,
    up.TotalReputation AS TopUserReputation,
    up.BadgeCount AS TopUserBadgeCount,
    COALESCE(vc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vc.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN p.ParentId IS NOT NULL THEN 'Answer'
        ELSE 'Question'
    END AS PostType,
    r.Level AS HierarchyLevel
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation up ON up.UserId = p.OwnerUserId
LEFT JOIN 
    VoteCounts vc ON vc.PostId = p.Id
JOIN 
    RecursivePostHierarchy r ON r.Id = p.Id
WHERE 
    (p.ViewCount > 100 OR p.Score > 10) -- Filter for popular posts
    AND (p.CreationDate >= NOW() - INTERVAL '1 year') -- Posts from the last year
ORDER BY 
    r.Level, p.CreationDate DESC;
