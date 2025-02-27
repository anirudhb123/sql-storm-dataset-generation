WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Only questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) >= 5  -- Only consider users with at least 5 questions
),
UserBadges AS (
    SELECT 
        b.UserId,
        ARRAY_AGG(b.Name) AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.TotalScore,
    COALESCE(ub.BadgeNames, ARRAY[]::varchar[]) AS BadgeNames,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerDisplayName AND rp.PostRank = 1
ORDER BY 
    tu.TotalScore DESC, tu.QuestionCount DESC
LIMIT 10;
