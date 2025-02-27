WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.UserPostRank,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ub.BadgeCount,
        ub.GoldBadge,
        ub.SilverBadge,
        ub.BronzeBadge
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    ps.UserPostRank,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.BadgeCount,
    ps.GoldBadge,
    ps.SilverBadge,
    ps.BronzeBadge
FROM 
    PostStatistics ps
WHERE 
    ps.UserPostRank <= 5
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 10;
