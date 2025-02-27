WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(DISTINCT b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ua.TotalBounties,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(rp.CommentCount, 0) AS TotalComments
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON rp.Id = (
        SELECT p.Id 
        FROM RankedPosts p 
        WHERE p.PostRank = 1 AND p.OwnerUserId = u.Id
        LIMIT 1
    )
WHERE 
    ua.Reputation >= 1000
ORDER BY 
    ua.TotalBounties DESC, 
    ua.Reputation DESC
LIMIT 10;
