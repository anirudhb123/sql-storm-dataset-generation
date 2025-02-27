WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, ub.BadgeCount
    ORDER BY 
        TotalScore DESC, BadgeCount DESC
    LIMIT 10
)
SELECT 
    ru.PostId,
    ru.Title,
    ru.CreationDate,
    ru.OwnerDisplayName,
    ru.Score,
    ru.ViewCount,
    tu.DisplayName AS TopUserDisplayName,
    tu.BadgeCount AS TopUserBadgeCount,
    tu.TotalScore AS TopUserTotalScore
FROM 
    RankedPosts ru
JOIN 
    TopUsers tu ON ru.OwnerUserId = tu.UserId
WHERE 
    ru.RankByScore <= 3 -- Get the top 3 ranked questions per user
ORDER BY 
    ru.Score DESC, ru.CreationDate DESC;
