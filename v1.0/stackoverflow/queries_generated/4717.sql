WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(bp.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT DISTINCT UserId, BountyAmount FROM Votes WHERE BountyAmount > 0) bp ON u.Id = bp.UserId
    GROUP BY 
        u.Id
)

SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalBounties,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    UserStats us
INNER JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.Reputation > 1000
    AND rp.rn <= 3
ORDER BY 
    us.Reputation DESC, rp.Score DESC
LIMIT 10;

WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Class,
        b.Name,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Class, b.Name
    HAVING 
        COUNT(b.Id) > 1
)

SELECT 
    ub.UserId,
    SUM(CASE WHEN ub.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN ub.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN ub.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    UserBadges ub
GROUP BY 
    ub.UserId
HAVING 
    SUM(CASE WHEN ub.Class = 1 THEN 1 ELSE 0 END) > 0

UNION ALL

SELECT 
    u.Id AS UserId,
    0 AS GoldBadges,
    0 AS SilverBadges,
    COUNT(b.Id) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 3
WHERE 
    u.Id NOT IN (SELECT UserId FROM UserBadges)
GROUP BY 
    u.Id
ORDER BY 
    UserId;
