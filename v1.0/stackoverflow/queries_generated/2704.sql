WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserId AS CloserId,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS CloseActions
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    up.DisplayName,
    up.Reputation,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    MAX(rp.Score) AS HighestScore,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    STRING_AGG(DISTINCT ub.BadgeNames, '; ') AS AllBadges,
    SUM(CASE WHEN cp.CloseActions > 0 THEN 1 ELSE 0 END) AS ClosedCount
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.Rank <= 5
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    up.Reputation > 100
GROUP BY 
    up.Id, up.DisplayName, up.Reputation
HAVING 
    COUNT(DISTINCT rp.PostId) > 2
ORDER BY 
    TotalPosts DESC, HighestScore DESC;
