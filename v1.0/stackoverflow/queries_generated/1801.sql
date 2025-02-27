WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 -- Only questions with a positive score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
)
SELECT 
    u.DisplayName,
    up.PostId,
    up.Title,
    up.Score,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(cp.CreationDate, 'No Closure') AS ClosureDate
FROM 
    Users u
JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON up.PostId = cp.PostId
WHERE 
    up.UserRank = 1 -- Highest scored question per user
ORDER BY 
    u.Reputation DESC, 
    up.Score DESC;
