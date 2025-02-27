WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostCommentStats AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
), PopularPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        COALESCE(pcs.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCommentStats pcs ON rp.Id = pcs.PostId
)
SELECT 
    pp.Id, 
    pp.Title, 
    pp.CreationDate, 
    pp.Score, 
    pp.CommentCount, 
    ub.BadgeCount AS UserBadgeCount, 
    ub.GoldCount, 
    ub.SilverCount, 
    ub.BronzeCount
FROM 
    PopularPosts pp
JOIN 
    Users u ON pp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    pp.Score = (SELECT MAX(Score) FROM PopularPosts) 
ORDER BY 
    pp.CommentCount DESC
LIMIT 10;
