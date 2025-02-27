WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 0
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    tu.BadgeCount,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    COALESCE((SELECT AVG(v.BountyAmount) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId IN (8, 9)), 0) AS AvgBountyAmount
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.CreatorId
WHERE 
    rp.rn = 1
ORDER BY 
    tu.TotalScore DESC, 
    rp.ViewCount DESC
LIMIT 10;
