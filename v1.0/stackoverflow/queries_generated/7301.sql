WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
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
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts + (ua.TotalComments * 0.5) + (ua.TotalUpVotes * 2) - (ua.TotalDownVotes * 1) AS ActivityScore
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 0 OR ua.TotalComments > 0
    ORDER BY 
        ActivityScore DESC
    LIMIT 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.ActivityScore,
    COUNT(DISTINCT ph.Id) AS TotalPostHistoryEdits
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistory ph ON tu.UserId = ph.UserId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.ActivityScore
ORDER BY 
    TotalPostHistoryEdits DESC;
