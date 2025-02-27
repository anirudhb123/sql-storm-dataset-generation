WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownvotes,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalUpvotes,
        TotalDownvotes,
        AvgViewCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts,
        RANK() OVER (ORDER BY TotalUpvotes DESC) AS RankByUpvotes
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.AvgViewCount,
    (tu.RankByPosts + tu.RankByUpvotes) / 2.0 AS OverallRank
FROM 
    TopUsers tu
WHERE 
    tu.PostCount > 5
ORDER BY 
    OverallRank ASC
LIMIT 10;
