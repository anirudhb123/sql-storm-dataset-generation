WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.TotalBounty,
    up.BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    UserStats up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    up.TotalBounty > (
        SELECT AVG(TotalBounty) FROM UserStats
    )
    AND rp.ScoreRank <= 5
ORDER BY 
    up.TotalBounty DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
