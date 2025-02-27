WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 AND 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(rp.Score) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    ub.BadgeNames,
    COALESCE(NULLIF(tu.TotalScore::text, '0'), 'No score') AS ScoreDescription,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tu.PostCount > 5
ORDER BY 
    tu.TotalScore DESC, tu.DisplayName ASC
LIMIT 50;

-- This query benchmarks performance across nested CTEs considering users' posts, scores, and badges, 
-- handling NULL logic and utilizing window functions for ranking.
