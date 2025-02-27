WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Depth + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostsWithDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(r.Depth, 0) AS PostDepth,
        ur.Reputation AS OwnerReputation,
        ur.TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecursivePostHierarchy r ON p.Id = r.PostId
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
)
SELECT 
    pwd.PostId, 
    pwd.Title,
    pwd.Score,
    pwd.ViewCount,
    pwd.OwnerDisplayName,
    pwd.PostDepth,
    pwd.OwnerReputation,
    pwd.TotalBounty,
    CASE 
        WHEN pwd.Score >= 10 THEN 'High Score'
        WHEN pwd.Score >= 5  THEN 'Medium Score'
        WHEN pwd.Score < 5   THEN 'Low Score' 
        ELSE 'No Score' 
    END AS ScoreCategory
FROM 
    PostsWithDetails pwd
WHERE 
    pwd.OwnerReputation > 1000
ORDER BY 
    pwd.ViewCount DESC;
