WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pe.CommentCount,
    pe.UpVoteCount,
    pe.DownVoteCount,
    COALESCE(ub.GoldBadges, 0) AS UserGoldBadges,
    COALESCE(ub.SilverBadges, 0) AS UserSilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS UserBronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
JOIN 
    PostEngagement pe ON rp.Id = pe.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC;
