WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(crt.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened posts
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    COUNT(DISTINCT rp.Id) AS RecentPosts,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    cr.CloseReasonNames,
    SUM(CASE 
        WHEN rp.ViewCount > 1000 THEN 1 ELSE 0 
    END) AS PostsOver1000Views
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.rn <= 5
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostComments pc ON rp.Id = pc.PostId
LEFT JOIN 
    CloseReasons cr ON rp.Id = cr.PostId
WHERE 
    up.Reputation > 1000
GROUP BY 
    up.Id, up.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, cr.CloseReasonNames
ORDER BY 
    RecentPosts DESC, up.DisplayName;
