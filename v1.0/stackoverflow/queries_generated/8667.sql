WITH UserScores AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           u.UpVotes,
           u.DownVotes,
           (u.UpVotes - u.DownVotes) AS NetVotes,
           COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT UserId,
           DisplayName,
           Reputation,
           TotalPosts,
           QuestionCount,
           AnswerCount,
           AcceptedAnswers,
           NetVotes,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserScores
    WHERE Reputation > 0
),
RecentPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.ViewCount,
           p.Score,
           u.DisplayName AS OwnerDisplayName,
           p.PostTypeId,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.AcceptedAnswers,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName
FROM TopUsers tu
JOIN RecentPosts rp ON tu.UserId = rp.OwnerDisplayName
WHERE tu.Rank <= 10 AND rp.RecentRank <= 5
ORDER BY tu.Rank, rp.CreationDate DESC;
