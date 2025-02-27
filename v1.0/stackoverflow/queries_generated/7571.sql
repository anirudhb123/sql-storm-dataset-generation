WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        SUM(v.VoteTypeId IN (4, 10, 11)) AS TotalModerationVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        ua.TotalModerationVotes,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY ua.TotalUpVotes DESC) AS VoteRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.TotalModerationVotes,
    CASE 
        WHEN tu.PostRank = 1 THEN 'Top Poster'
        WHEN tu.VoteRank = 1 THEN 'Top Voter'
        ELSE 'Active User'
    END AS UserType
FROM 
    TopUsers tu
WHERE 
    tu.PostRank <= 10 OR tu.VoteRank <= 10
ORDER BY 
    tu.PostRank, tu.VoteRank;
