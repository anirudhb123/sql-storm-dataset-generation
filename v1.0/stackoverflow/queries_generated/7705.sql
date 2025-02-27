WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        COUNT(rp.PostId) AS PostCount
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    JOIN 
        Users ub ON b.UserId = ub.Id
    GROUP BY 
        ub.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    tu.PostCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tu.TotalScore > 1000 -- Threshold for notable users
ORDER BY 
    tu.TotalScore DESC, 
    tu.PostCount DESC
LIMIT 10;
