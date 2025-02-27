WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 0
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS TotalUpvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBounty,
    us.TotalUpvotes,
    us.TotalPosts,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    cp.CreationDate AS PostClosedDate,
    COALESCE(cp.Comment, 'Not Closed') AS CloseComment
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId 
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.TotalBounty DESC, 
    us.TotalUpvotes DESC, 
    us.TotalPosts DESC
LIMIT 50;
