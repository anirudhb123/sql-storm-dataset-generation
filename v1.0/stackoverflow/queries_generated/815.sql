WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser,
        SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId IN (8, 9)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
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
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(rp.TotalBounty, 0) AS TotalBounty
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.RankPerUser <= 3
ORDER BY 
    rp.Score DESC, 
    u.Reputation DESC
LIMIT 50;
