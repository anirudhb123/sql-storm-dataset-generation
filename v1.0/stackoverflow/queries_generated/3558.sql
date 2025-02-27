WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COUNT(DISTINCT pc.CommentCount) AS TotalComments,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY SUM(p.Score) DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT 
    ps.PostId,
    ps.Title,
    CASE 
        WHEN ps.GoldBadges > 0 THEN 'Gold'
        WHEN ps.SilverBadges > 0 THEN 'Silver'
        WHEN ps.BronzeBadges > 0 THEN 'Bronze'
        ELSE 'No Badges'
    END AS BadgeStatus,
    ps.CreationDate,
    ps.TotalComments,
    ps.PopularityRank
FROM 
    PostStatistics ps
WHERE 
    ps.PopularityRank <= 10
ORDER BY 
    ps.PopularityRank;
