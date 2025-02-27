WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    ur.UserId,
    ur.Reputation,
    ur.PostCount,
    ur.BadgeCount,
    COALESCE(rp.CommentCount, 0) AS TotalComments
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    ur.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 10
UNION ALL
SELECT 
    NULL AS PostId,
    'Total Users with High Reputation' AS Title,
    NULL AS Score,
    NULL AS CreationDate,
    NULL AS UserId,
    COUNT(*) AS Reputation,
    NULL AS PostCount,
    NULL AS BadgeCount,
    NULL AS TotalComments
FROM 
    Users
WHERE 
    Reputation > 1000
HAVING 
    COUNT(*) > 5;
