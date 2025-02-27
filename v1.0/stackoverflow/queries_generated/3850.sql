WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.ViewCount IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostEditHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24)
)
SELECT 
    up.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN ub.BadgeCount IS NULL THEN 0 ELSE ub.BadgeCount END) AS TotalBadges,
    MAX(rp.ViewCount) AS HighestViewCount,
    STRING_AGG(DISTINCT CAST(pe.Comment AS VARCHAR), '; ') AS RecentEdits
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostEditHistory pe ON up.Id = pe.UserId
WHERE 
    up.Reputation > 100
GROUP BY 
    up.Id
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    TotalPosts DESC, HighestViewCount DESC;
