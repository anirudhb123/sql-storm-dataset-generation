WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScores
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    tu.TotalBadges,
    tu.TotalPosts,
    tu.TotalScores
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = tu.UserId AND 
            rp.UserPostRank <= 3
    )
JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.CommentCount > 0
ORDER BY 
    tu.TotalScores DESC, 
    rp.CreationDate DESC
LIMIT 10;

-- Additional insight on highly ranked posts with badges earned by users in the last month
WITH RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS RecentBadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 month'
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    rb.RecentBadgeCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecentBadges rb ON u.Id = rb.UserId
GROUP BY 
    u.DisplayName, rb.RecentBadgeCount
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalPosts DESC;
