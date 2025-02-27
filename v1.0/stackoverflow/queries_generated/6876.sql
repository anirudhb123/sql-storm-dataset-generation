WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = u.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalCommentScore,
        TotalBadges,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalAnswers,
    tu.TotalQuestions,
    tu.TotalCommentScore,
    tu.TotalBadges,
    ph.Name AS PostHistoryType,
    ph.CreationDate AS LastActivityDate
FROM TopUsers tu
JOIN Posts p ON tu.UserId = p.OwnerUserId
JOIN PostHistory ph ON p.Id = ph.PostId
WHERE tu.ReputationRank <= 10
  AND ph.CreationDate = (
      SELECT MAX(CreationDate)
      FROM PostHistory
      WHERE PostId = p.Id
  )
ORDER BY tu.Reputation DESC, tu.DisplayName;
