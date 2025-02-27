WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(vs.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vs ON p.Id = vs.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCount,
        CommentsCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    tu.Rank,
    tu.UserId,
    tu.DisplayName,
    tu.PostsCount,
    tu.CommentsCount,
    tu.TotalScore,
    pt.Name AS PostType,
    bh.Name AS BadgeType
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE OwnerUserId = tu.UserId LIMIT 1)
LEFT JOIN 
    PostHistoryTypes bh ON bh.Id = (SELECT PostHistoryTypeId FROM PostHistory WHERE UserId = tu.UserId LIMIT 1)
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
