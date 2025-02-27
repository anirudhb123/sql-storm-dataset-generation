WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC, p.Title) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
), UserBounties AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount,
        ARRAY_AGG(DISTINCT crt.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post Closed, Post Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rb.TotalBountyAmount,
    ub.DisplayName,
    ub.TotalBountySpent,
    cp.FirstClosedDate,
    cp.CloseCount,
    cp.CloseReasons,
    CASE 
        WHEN rp.ViewRank = 1 
        THEN 'Most Viewed' 
        ELSE 'Regular Post' 
    END AS PostTag,
    CASE 
        WHEN cp.CloseCount > 0 
        THEN 'Closed'
        ELSE 'Active' 
    END AS Status
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBounties ub ON rp.PostId = ub.UserId 
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.TotalComments > 0
ORDER BY 
    rp.ViewCount DESC, 
    rp.TotalBountyAmount DESC;
