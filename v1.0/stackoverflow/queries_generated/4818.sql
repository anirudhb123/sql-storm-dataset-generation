WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate, 
        DisplayName,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostScore AS (
    SELECT 
        OwnerUserId, 
        SUM(Score) AS TotalScore, 
        COUNT(Id) AS PostCount 
    FROM Posts 
    GROUP BY OwnerUserId
), 
TopUsers AS (
    SELECT 
        u.UserId, 
        u.DisplayName, 
        pr.TotalScore, 
        pr.PostCount, 
        (u.Reputation + COALESCE(pr.TotalScore, 0)) AS CombinedScore
    FROM UserReputation u
    LEFT JOIN PostScore pr ON u.UserId = pr.OwnerUserId
    WHERE u.Reputation > 1000
)

SELECT 
    tu.DisplayName, 
    tu.TotalScore, 
    tu.PostCount, 
    tu.CombinedScore,
    CASE 
        WHEN tu.CombinedScore >= 5000 THEN 'Expert'
        WHEN tu.CombinedScore >= 2000 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel,
    p.Title,
    p.Score AS PostScore,
    COALESCE(c.CommentCount, 0) AS CommentCount
FROM TopUsers tu
LEFT JOIN Posts p ON tu.UserId = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(Id) AS CommentCount 
    FROM Comments 
    GROUP BY PostId
) c ON p.Id = c.PostId
JOIN (
    SELECT DISTINCT UserId 
    FROM Votes 
    WHERE VoteTypeId IN (2, 3) -- Count only Upvotes and Downvotes
) v ON v.UserId = tu.UserId
WHERE tu.ReputationRank <= 10
ORDER BY tu.CombinedScore DESC, p.Score DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
