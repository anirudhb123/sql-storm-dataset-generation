WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserWithBestPosts AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AverageScore,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY ps.AverageScore DESC) AS RankWithinReputation
    FROM UserReputation ur
    JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    uwb.UserId,
    uwb.DisplayName,
    uwb.Reputation,
    uwb.TotalPosts,
    uwb.TotalQuestions,
    uwb.TotalAnswers,
    uwb.AverageScore
FROM UserWithBestPosts uwb
WHERE uwb.RankWithinReputation = 1 
      AND uwb.Reputation > (SELECT AVG(Reputation) FROM UserReputation)
      AND NOT EXISTS (
          SELECT 1
          FROM Posts p
          WHERE p.OwnerUserId = uwb.UserId
          AND p.CreationDate < NOW() - INTERVAL '1 year'
      )
ORDER BY uwb.Reputation DESC
LIMIT 10;

SELECT DISTINCT 
    u.DisplayName,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM Users u
LEFT JOIN Votes v ON u.Id = v.UserId
GROUP BY u.DisplayName
HAVING COUNT(v.Id) > 5
ORDER BY TotalBounty DESC;
