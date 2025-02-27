WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        CreationDate,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    p.PostId,
    p.Title,
    COALESCE(rh.Level, 0) AS HierarchyLevel,
    ur.DisplayName AS OwnerName,
    ur.TotalReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS Upvotes,
    SUM(v.VoteTypeId = 3) AS Downvotes,
    MAX(CASE 
        WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 1 
        ELSE 0 
    END) AS IsOldPost,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(ph.Comment) AS LastEditComment
FROM 
    RecursivePostHierarchy rh
LEFT JOIN 
    Posts p ON p.Id = rh.PostId
LEFT JOIN 
    Users ur ON p.OwnerUserId = ur.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    RecentPostHistory ph ON ph.PostId = p.Id AND ph.rn = 1
GROUP BY 
    p.PostId, p.Title, rh.Level, ur.DisplayName, ur.TotalReputation
ORDER BY 
    COALESCE(ur.TotalReputation, 0) DESC, p.CreationDate DESC;
