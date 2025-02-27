WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT *,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    CASE 
        WHEN tu.ReputationRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM TopUsers tu
WHERE tu.TotalPosts > 0
  AND EXISTS (
      SELECT 1 
      FROM Posts p
      WHERE p.OwnerUserId = tu.UserId 
        AND p.LastActivityDate > NOW() - INTERVAL '1 YEAR'
  )
ORDER BY tu.Reputation DESC, tu.TotalPosts DESC
LIMIT 20;
