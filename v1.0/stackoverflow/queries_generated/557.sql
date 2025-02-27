WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS comment_count
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
TopUsers AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName,
        SUM(p.Score) AS total_score,
        COUNT(DISTINCT p.Id) AS total_posts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS badge_count,
        STRING_AGG(b.Name, ', ') AS badge_names
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    tu.DisplayName,
    tu.total_score,
    tu.total_posts,
    ub.badge_count,
    COALESCE(ub.badge_names, 'No badges') AS badge_names,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.comment_count
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.user_id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON tu.user_id = rp.OwnerUserId AND rp.rn = 1
ORDER BY 
    tu.total_score DESC, 
    rp.Score DESC NULLS LAST
LIMIT 10;
