WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 100
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.Count, 0) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS Count 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.TotalBounties,
    rp.Title,
    rp.Score,
    rp.ViewCount
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank <= 3
ORDER BY 
    us.Reputation DESC, rp.Score DESC
LIMIT 10
UNION ALL
SELECT 
    'Total', 
    NULL, 
    COUNT(DISTINCT u.Id) AS UniqueUsers, 
    SUM(b.Count) AS TotalBadges, 
    SUM(v.BountyAmount) AS TotalBounties
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
WHERE 
    EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id)
HAVING 
    COUNT(DISTINCT p.Id) > 0;
