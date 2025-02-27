WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnedUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(b.Class) AS BadgeClassCount
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        us.DisplayName,
        us.TotalPosts,
        us.PositivePosts,
        us.NegativePosts,
        RANK() OVER (ORDER BY us.TotalPosts DESC, us.PositivePosts DESC) AS UserRank
    FROM 
        UserStats us
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.PositivePosts,
    tu.NegativePosts,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    nullif(rp.ViewCount, 0) AS Views,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostType
FROM 
    TopUsers tu
LEFT JOIN RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
