WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (1, 4)) AS TitleEditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    us.Reputation,
    us.PostsCount,
    us.TotalBounties,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(ph.CloseCount, 0) AS CloseCount,
    ph.TitleEditCount,
    CASE 
        WHEN us.Reputation > 1000 THEN 'High Rep User'
        WHEN us.Reputation IS NULL THEN 'New User'
        ELSE 'Mid Rep User'
    END AS ReputationCategory
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
WHERE 
    us.PostsCount > 5
ORDER BY 
    us.Reputation DESC, rp.CreationDate DESC;
