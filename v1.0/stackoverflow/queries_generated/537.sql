WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100 -- Only users with total score greater than 100
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 OR b.Class = 2 -- Gold or Silver badges
    GROUP BY 
        b.UserId
)
SELECT 
    tu.DisplayName,
    tr.Title,
    tr.CreationDate,
    tr.Score,
    tr.AnswerCount,
    tr.ViewCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers tu
JOIN 
    RankedPosts tr ON tu.UserId = tr.OwnerUserId
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tr.rn = 1 -- Only the highest scored post for each user
ORDER BY 
    tu.TotalScore DESC, tu.TotalPosts DESC, tr.ViewCount DESC
LIMIT 10;

-- Additional metrics and filters can be implemented as required to extend this query further.
