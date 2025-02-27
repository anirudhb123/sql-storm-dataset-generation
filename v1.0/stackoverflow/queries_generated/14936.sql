-- Performance benchmarking query for Stack Overflow schema
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalBadges,
        TotalBounty,
        TotalPosts,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Ranking
    FROM 
        UserStats
    WHERE 
        TotalPosts > 0
)
SELECT 
    UserId,
    Reputation,
    TotalBadges,
    TotalBounty,
    TotalPosts,
    TotalComments,
    Ranking
FROM 
    TopUsers
WHERE 
    Ranking <= 10
ORDER BY 
    Ranking;
