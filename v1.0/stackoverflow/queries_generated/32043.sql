WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        1 AS Depth
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostActivities AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.Id END) AS DeleteCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) /* BountyStart, BountyClose */
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
PostMetrics AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.OwnerUserId,
        pa.CreationDate,
        pa.CommentCount,
        pa.TotalBounty,
        pa.CloseCount,
        pa.DeleteCount,
        pa.CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY pa.OwnerUserId ORDER BY pa.CommentCount DESC) AS CommentRank,
        AVG(DATEDIFF(MINUTE, pa.CreationDate, NOW())) OVER (PARTITION BY pa.OwnerUserId) AS AvgPostAge
    FROM 
        PostActivities pa
)
SELECT 
    um.Id AS UserId,
    um.DisplayName,
    pm.PostId,
    pm.Title,
    pm.CommentCount,
    pm.TotalBounty,
    pm.CloseCount,
    pm.DeleteCount,
    pm.CloseReopenCount,
    pm.CommentRank,
    pm.AvgPostAge
FROM 
    Users um
LEFT JOIN 
    PostMetrics pm ON um.Id = pm.OwnerUserId
WHERE 
    pm.CommentCount > 0
ORDER BY 
    um.Reputation DESC, pm.CommentCount DESC;
