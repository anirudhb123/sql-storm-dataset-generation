
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
),
PostScoreSummary AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        RecentPosts rp
    GROUP BY 
        rp.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        us.PostCount,
        us.TotalScore,
        us.AvgViewCount,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS ScoreRank
    FROM 
        Users u
    JOIN 
        PostScoreSummary us ON u.Id = us.OwnerUserId
    WHERE 
        u.Reputation > 100 
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.AvgViewCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(GROUP_CONCAT(b.Name SEPARATOR ', '), 'No Badges') AS BadgeNames
FROM 
    TopUsers tu
LEFT JOIN (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
) b ON tu.UserId = b.UserId
WHERE 
    tu.ScoreRank <= 10 
ORDER BY 
    tu.TotalScore DESC;
