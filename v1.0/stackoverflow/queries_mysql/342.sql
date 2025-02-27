
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        rp.UserRank,
        COALESCE(rp.CommentCount, 0) AS TotalComments
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.PostId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.UserRank,
    tu.TotalComments,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS TagList
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    Tags t ON FIND_IN_SET(t.Id, p.Tags)
WHERE 
    tu.TotalComments >= 5
GROUP BY 
    tu.DisplayName, tu.BadgeCount, tu.UserRank, tu.TotalComments
ORDER BY 
    tu.BadgeCount DESC, tu.UserRank ASC;
