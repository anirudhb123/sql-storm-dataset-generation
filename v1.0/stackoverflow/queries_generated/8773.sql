WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBounties,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalComments DESC) AS Rank
    FROM 
        UserActivity
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalBounties,
    ub.BadgeCount
FROM 
    TopUsers tu
JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
