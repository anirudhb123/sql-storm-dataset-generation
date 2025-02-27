WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
        AND p.Score > 10
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
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
)
SELECT 
    up.UserId,
    u.DisplayName,
    bp.PostId,
    bp.Title,
    bp.ViewCount,
    bp.Score,
    ub.BadgeCount
FROM 
    Users up
JOIN 
    RankedPosts bp ON up.Id = bp.PostId
JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    bp.Rank <= 5 
ORDER BY 
    ub.BadgeCount DESC, bp.Score DESC
LIMIT 100;
