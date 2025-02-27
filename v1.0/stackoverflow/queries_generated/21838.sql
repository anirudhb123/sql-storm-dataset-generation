WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    AND 
        p.ViewCount IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    up.PostCount,
    up.TotalBadgeClass,
    rp.Title,
    rp.ViewCount,
    COALESCE(cp.LastClosedDate, 'No closes') AS LastClosedDate,
    CASE 
        WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    UserReputation up
JOIN 
    Users u ON u.Id = up.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    up.TotalBadgeClass > 5 
ORDER BY 
    up.TotalBadgeClass DESC, 
    u.Reputation DESC
LIMIT 10;

-- Subquery with a set operator example for more complex logic
UNION ALL 

SELECT 
    'N/A' AS DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    0 AS TotalBadgeClass,
    NULL AS Title,
    SUM(p.ViewCount) AS TotalViewCount,
    NULL AS LastClosedDate,
    'Aggregate' AS PostStatus
FROM 
    Posts p
WHERE 
    p.ViewCount IS NOT NULL
GROUP BY 
    p.OwnerUserId;
