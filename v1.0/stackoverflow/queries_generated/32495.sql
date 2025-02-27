WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p 
    INNER JOIN 
        Posts a ON p.ParentId = a.Id  -- Getting Answers
    WHERE 
        a.PostTypeId = 2
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors,
        STRING_AGG(DISTINCT CASE WHEN pht.Name = 'Post Closed' THEN 'Closed' END, ', ') AS Status
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    us.DisplayName AS OwnerDisplayName,
    us.Reputation AS OwnerReputation,
    us.TotalBounty,
    us.TotalPosts,
    us.TotalCommentScore,
    ph.LastChangeDate,
    ph.UniqueEditors,
    ph.Status
FROM 
    RecursivePostCTE r
JOIN 
    Users us ON us.Id = r.OwnerUserId
LEFT JOIN 
    PostHistoryDetails ph ON ph.PostId = r.PostId
WHERE 
    r.Level = 1  -- Only direct Questions
    AND r.Score > 5  -- Only popular Questions
ORDER BY 
    r.Score DESC,
    r.ViewCount DESC;
