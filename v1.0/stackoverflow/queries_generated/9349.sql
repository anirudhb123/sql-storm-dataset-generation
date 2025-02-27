WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount
FROM 
    UserBadges up
JOIN 
    RankedPosts rp ON rp.rn = 1 AND rp.PostId IN (
        SELECT 
            PostId 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = up.UserId 
        ORDER BY 
            CreationDate DESC 
        LIMIT 5
    )
WHERE 
    up.BadgeCount > 0
ORDER BY 
    up.BadgeCount DESC, rp.Score DESC
LIMIT 10;
