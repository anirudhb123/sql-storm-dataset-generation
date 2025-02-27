
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, CAST('2024-10-01' AS DATE))
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS BadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),

TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeScore,
        RANK() OVER (ORDER BY ur.Reputation + ur.BadgeScore DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation > 1000
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    tu.UserId,
    tu.Reputation,
    tu.BadgeScore
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.PostRank = 1
    AND (rp.Score IS NULL OR rp.Score > 10)
    AND rp.ViewCount IS NOT NULL
    AND (DATEPART(WEEKDAY, rp.CreationDate) IN (0, 6) OR (DATEPART(HOUR, rp.CreationDate) BETWEEN 8 AND 18))
ORDER BY 
    tu.UserRank, rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
