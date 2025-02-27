WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
MostActiveUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS PostCount,
        MAX(CreationDate) AS LastPostDate
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        UserId
    HAVING 
        COUNT(*) > 5
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    u.DisplayName AS Owner,
    ur.TotalBadges,
    ur.TotalBounty,
    mu.PostCount,
    mu.LastPostDate
FROM 
    RankedPosts r
JOIN 
    Users u ON r.PostId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    MostActiveUsers mu ON u.Id = mu.UserId
WHERE 
    r.PostRank = 1
    AND (ur.TotalBounty IS NULL OR ur.TotalBounty > 0)
ORDER BY 
    r.Score DESC, 
    r.ViewCount DESC;
