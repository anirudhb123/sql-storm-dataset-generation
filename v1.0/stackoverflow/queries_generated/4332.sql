WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPostCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
)

SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalBounties,
    u.TotalBadges,
    COALESCE(cpc.ClosedPostCount, 0) AS ClosedPosts,
    CASE 
        WHEN cpc.ClosedPostCount >= 5 THEN 'Frequent Closure'
        WHEN cpc.ClosedPostCount IS NOT NULL THEN 'Occasional Closure'
        ELSE 'No Closure'
    END AS ClosureStatus,
    rp.PostId,
    rp.Title,
    rp.Score
FROM 
    UserStats u
LEFT JOIN 
    ClosedPostCounts cpc ON u.UserId = cpc.UserId
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.rn = 1
ORDER BY 
    u.TotalPosts DESC,
    u.DisplayName;
