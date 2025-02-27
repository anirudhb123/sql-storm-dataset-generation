
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS UserRank,
        @prev_owner := p.OwnerUserId,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p, (SELECT @row_num := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2022-01-01'
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.UserId,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    pvc.UpVotes,
    pvc.DownVotes,
    CASE WHEN rp.UserRank = 1 THEN 'Top Post' ELSE 'Regular Post' END AS PostType
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostVoteCounts pvc ON rp.Id = pvc.PostId
WHERE 
    (rp.TotalPosts > 1 OR ub.GoldBadges IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
