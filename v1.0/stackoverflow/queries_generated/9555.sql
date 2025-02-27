WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
), 
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 10
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY pp.Score DESC) AS Rank
    FROM 
        UserStats us
    JOIN 
        PopularPosts pp ON us.UserId = pp.OwnerUserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.Title AS MostPopularPostTitle,
    tu.Score AS PostScore,
    tu.ViewCount AS PostViewCount,
    COUNT(DISTINCT t.Id) AS TagCount,
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.PostId = p.Id
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS t ON 1=1
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
WHERE 
    tu.Rank = 1
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.Title, tu.Score, tu.ViewCount
ORDER BY 
    tu.Reputation DESC, tu.PostScore DESC
LIMIT 10;
