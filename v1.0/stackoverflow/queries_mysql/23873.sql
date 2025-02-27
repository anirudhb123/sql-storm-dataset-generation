
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,  
        COUNT(c.Id) AS CommentCount, 
        SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rn := 0, @prevOwnerUserId := NULL) AS vars
    WHERE p.CreationDate > DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
    GROUP BY p.Id, p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    COALESCE(pp.PostId, -1) AS PostId, 
    pp.CommentCount,
    pp.VoteCount
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN PopularPosts pp ON u.Id = pp.OwnerUserId AND pp.rn = 1
WHERE ur.Reputation IS NOT NULL
ORDER BY ur.Reputation DESC, pp.VoteCount DESC
LIMIT 10;
