WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        ph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.Id
)
, UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
)
, PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
)
, EditsHistory AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    up.Title AS PopularPostTitle,
    up.Score AS PopularPostScore,
    up.CreationDate AS PopularPostCreationDate,
    ph.Id AS HierarchyPostId,
    ph.Title AS HierarchyPostTitle,
    ph.Level AS HierarchyLevel,
    eh.FirstEditDate,
    eh.LastEditDate,
    eh.EditCount
FROM 
    UserReputation u
LEFT JOIN 
    PopularPosts up ON u.UserId = up.OwnerUserId AND up.PostRank = 1
LEFT JOIN 
    PostHierarchy ph ON ph.Id = up.Id
LEFT JOIN 
    EditsHistory eh ON eh.PostId = up.Id
WHERE 
    u.Reputation > 500 -- Only users with more than 500 reputation
ORDER BY 
    u.Reputation DESC,
    up.Score DESC,
    ph.Level;
