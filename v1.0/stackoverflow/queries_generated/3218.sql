WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount > 100
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        PHT.Name AS HistoryType 
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
        AND ph.UserId IS NOT NULL
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalViews,
    us.TotalBounties,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(rph.Comment, 'No recent history') AS RecentComment,
    COALESCE(rph.HistoryType, 'No changes') AS HistoryType
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    RecentPostHistory rph ON rp.Id = rph.PostId
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.TotalViews DESC, us.TotalPosts DESC
LIMIT 100;
