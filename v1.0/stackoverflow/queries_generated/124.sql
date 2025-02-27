WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS UserRank
    FROM 
        UserStatistics
    WHERE 
        Reputation > 1000
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ut.PostCount,
    ut.TotalViews,
    ut.TotalUpvotes,
    ut.TotalDownvotes
FROM 
    TopUsers ut
JOIN 
    Users u ON ut.UserId = u.Id
WHERE 
    ut.UserRank <= 10
ORDER BY 
    ut.UserRank
UNION ALL
SELECT 
    'Aggregate' AS DisplayName,
    NULL AS Reputation,
    COUNT(*) AS PostCount,
    SUM(TotalViews) AS TotalViews,
    SUM(TotalUpvotes) AS TotalUpvotes,
    SUM(TotalDownvotes) AS TotalDownvotes
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    1;
