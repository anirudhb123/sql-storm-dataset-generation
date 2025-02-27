
WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(uc.BadgeCount, 0) AS TotalBadges,
        uc.GoldBadges,
        uc.SilverBadges,
        uc.BronzeBadges
    FROM 
        Users AS u
    LEFT JOIN 
        UserBadgeCounts AS uc ON u.Id = uc.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts AS p
    JOIN 
        TopUsers AS tu ON p.OwnerUserId = tu.Id
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBadges,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    TopUsers AS tu
INNER JOIN 
    RecentPosts AS rp ON tu.Id = rp.OwnerUserId
WHERE 
    rp.rn <= 3
ORDER BY 
    tu.Reputation DESC, rp.CreationDate DESC;
