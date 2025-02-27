WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
AggregatedPostData AS (
    SELECT 
        ph.PostId,
        ph.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.Score) AS MaxScore,
        AVG(u.Reputation) OVER (PARTITION BY ph.PostId) AS AverageReputation
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId AND v.VoteTypeId = 8 -- BountyStart votes
    LEFT JOIN 
        Users u ON u.Id = v.UserId
    GROUP BY 
        ph.PostId, ph.Title
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    apd.PostId,
    apd.Title,
    apd.CommentCount,
    apd.TotalBounty,
    apd.MaxScore,
    apd.AverageReputation,
    COALESCE(phd.ClosedDate, 'No Close Event') AS ClosedDate,
    COALESCE(phd.ReopenedDate, 'Not Reopened') AS ReopenedDate,
    CASE 
        WHEN phd.ClosedDate IS NOT NULL AND phd.ReopenedDate IS NULL THEN 'Closed'
        WHEN phd.ReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS Status
FROM 
    AggregatedPostData apd
LEFT JOIN 
    PostHistoryDetails phd ON apd.PostId = phd.PostId
ORDER BY 
    apd.CommentCount DESC, apd.TotalBounty DESC;
