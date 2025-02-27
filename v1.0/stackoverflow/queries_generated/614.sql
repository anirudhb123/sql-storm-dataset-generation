WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as PostRank
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
        SUM(p.Score) AS TotalScore, 
        SUM(b.Class = 1) AS GoldBadges
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= NOW() - INTERVAL '5 years' OR b.Id IS NULL
    GROUP BY 
        u.Id
    HAVING 
        TotalScore > 100
)
SELECT 
    tu.UserId, 
    tu.DisplayName, 
    tp.Title AS TopPostTitle, 
    tp.CreationDate, 
    tp.Score, 
    tp.CommentCount, 
    tu.TotalScore, 
    tu.GoldBadges
FROM 
    TopUsers tu
JOIN 
    RankedPosts tp ON tu.UserId = tp.OwnerUserId 
WHERE 
    tp.PostRank = 1
ORDER BY 
    tu.TotalScore DESC, 
    tp.Score DESC
LIMIT 10;


