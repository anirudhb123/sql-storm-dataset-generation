WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ContentLicense,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering questions
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 most viewed questions per user
),

UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    fb.PostId,
    fb.Title,
    fb.CreationDate,
    fb.ViewCount,
    fb.AnswerCount,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    Users u
JOIN 
    FilteredPosts fb ON u.Id = fb.OwnerUserId
JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000 -- Only users with high reputation
ORDER BY 
    fb.ViewCount DESC, 
    ub.BadgeCount DESC;
