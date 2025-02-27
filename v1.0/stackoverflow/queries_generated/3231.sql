WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ubc.BadgeCount, 0) AS TotalBadges,
        COALESCE(ubc.GoldBadges, 0) AS TotalGoldBadges
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ubc ON u.Id = ubc.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    ru.PostId,
    ru.Title,
    ru.CreationDate,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBadges,
    tu.TotalGoldBadges,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ru.PostId AND v.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ru.PostId AND v.VoteTypeId = 3) AS Downvotes
FROM 
    RankedPosts ru
JOIN 
    TopUsers tu ON ru.PostId = (SELECT PostId FROM RankedPosts WHERE RowNum = 1)
WHERE 
    ru.RowNum = 1
ORDER BY 
    ru.CreationDate DESC
LIMIT 10;
