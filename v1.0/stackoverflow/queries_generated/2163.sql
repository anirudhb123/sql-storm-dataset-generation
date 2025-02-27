WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
),
PostLinksCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INTEGER = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    ps.Reputation,
    ps.TotalPosts,
    ps.TotalBounties,
    pl.LinkCount,
    rc.CloseReasons
FROM 
    RankedPosts rp
JOIN 
    UserStats ps ON rp.OwnerUserId = ps.UserId
LEFT JOIN 
    PostLinksCounts pl ON rp.PostId = pl.PostId
LEFT JOIN 
    RecentCloseReasons rc ON rp.PostId = rc.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    ps.Reputation DESC,
    rp.CreationDate DESC
LIMIT 10;
