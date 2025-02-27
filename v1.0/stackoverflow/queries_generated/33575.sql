WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
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
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(rph.Level, 0) AS HierarchyLevel,
        u.DisplayName AS OwnerName,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHierarchy rph ON p.Id = rph.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.HierarchyLevel,
    pa.OwnerName,
    pa.OwnerReputation,
    pa.CommentCount,
    pa.UpvoteCount,
    tu.DisplayName AS TopUserDisplayName,
    tu.Upvotes AS TopUserUpvotes,
    tu.Downvotes AS TopUserDownvotes,
    tu.PostCount AS TopUserPostCount
FROM 
    PostAnalytics pa
LEFT JOIN 
    TopUsers tu ON pa.OwnerUserId = tu.Id
WHERE 
    pa.Score > 0
    AND pa.HierarchyLevel > 1
ORDER BY 
    pa.ViewCount DESC,
    pa.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
