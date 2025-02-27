WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        MAX(pc.CreationDate) AS LastCommentDate
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    pc.LastCommentDate,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.UserRank <= 3
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
