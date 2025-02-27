WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CreationDate,
        rp.ViewRank,
        ISNULL(rp.CommentCount, 0) AS TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewRank <= 10
), UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostsWithBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        up.BadgeCount,
        up.GoldBadges,
        up.SilverBadges,
        up.BronzeBadges
    FROM 
        RecentPosts p
    LEFT JOIN 
        UsersWithBadges up ON p.CommentCount = up.BadgeCount
)

SELECT 
    wp.PostId,
    wp.Title,
    wp.ViewCount,
    wp.AnswerCount,
    wp.TotalComments,
    wp.GoldBadges,
    COALESCE(wp.GoldBadges, 0) as SafeguardedGoldBadges,
    CASE 
        WHEN wp.SilverBadges IS NULL THEN 'No Silver!' 
        ELSE CONCAT('Silver count: ', wp.SilverBadges) 
    END AS SilverBadgeInfo,
    CASE 
        WHEN wp.BronzeBadges IS NOT NULL AND wp.BronzeBadges > 0 THEN 'Has Bronze!' 
        ELSE 'No Bronze!' 
    END AS BronzeBadgeInfo
FROM 
    PostsWithBadges wp
ORDER BY 
    wp.ViewCount DESC, wp.AnswerCount DESC
LIMIT 20
OFFSET (SELECT COUNT(*) FROM Posts) / 2; -- Bizarre pagination to show mid range
