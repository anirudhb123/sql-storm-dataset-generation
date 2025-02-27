WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
MostActiveUsers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 month'
    GROUP BY 
        p.OwnerUserId
    HAVING 
        COUNT(*) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    mau.PostCount,
    mau.TotalScore
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
JOIN 
    MostActiveUsers mau ON rp.OwnerUserId = mau.OwnerUserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
