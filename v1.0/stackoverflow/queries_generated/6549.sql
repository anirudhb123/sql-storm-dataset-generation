WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalUpVotes DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.LastPostDate,
    CASE 
        WHEN tu.TotalPosts > 100 THEN 'Expert'
        WHEN tu.TotalPosts BETWEEN 50 AND 100 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    COUNT(p.Id) AS TotalAcceptedAnswers
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId AND p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalComments, tu.TotalUpVotes, tu.TotalDownVotes, tu.LastPostDate
ORDER BY 
    tu.UserRank;
