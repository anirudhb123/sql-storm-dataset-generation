
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        @rank := IF(@prev_user = p.OwnerUserId, @rank + 1, 1) AS Rank,
        @prev_user := p.OwnerUserId,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN (SELECT @rank := 0, @prev_user := NULL) r 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(pv.Upvotes, 0) AS Upvotes,
    COALESCE(pv.Downvotes, 0) AS Downvotes,
    rp.CommentCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent Post'
        ELSE 'Other Posts'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    (ub.GoldBadges > 0 OR ub.SilverBadges > 0 OR ub.BronzeBadges > 0) 
    AND rp.ViewCount > 50
ORDER BY 
    rp.CreationDate DESC;
