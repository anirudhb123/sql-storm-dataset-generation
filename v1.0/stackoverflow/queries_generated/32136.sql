WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
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
        p.Score,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS RevisionCount,
        MAX(ph.CreationDate) AS LastEditedDate,
        MAX(ph.UserId) AS LastEditedBy
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    p.rph.Title AS ParentTitle,
    p.Rank,
    ph.RevisionCount,
    ph.LastEditedDate,
    u.DisplayName AS LastEditor
FROM 
    PostStatistics ps
LEFT JOIN 
    RecursivePostHierarchy rph ON ps.PostId = rph.PostId
LEFT JOIN 
    PostHistoryStats ph ON ps.PostId = ph.PostId
LEFT JOIN 
    Users u ON ph.LastEditedBy = u.Id
WHERE 
    ps.UpvoteCount - ps.DownvoteCount > 10
    AND ps.CommentCount > 5
ORDER BY 
    ps.CommentCount DESC,
    ps.PostRank ASC;
