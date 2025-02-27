-- Performance Benchmarking SQL Query for StackOverflow Schema

-- This query retrieves user reputation, post counts, and average vote score
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COALESCE(AVG(v.Score), 0) AS AvgVoteScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.Reputation
)
SELECT
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.AvgVoteScore,
    ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
FROM UserPostStats u
ORDER BY u.Reputation DESC, u.PostCount DESC;

-- This part of the query compares post activity over time
SELECT
    DATE_TRUNC('month', p.CreationDate) AS PostMonth,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM Posts p
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY PostMonth
ORDER BY PostMonth;

-- This final query evaluates the distribution of vote types on posts
SELECT
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.CreationDate >= NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentVotes
FROM VoteTypes vt
LEFT JOIN Votes v ON vt.Id = v.VoteTypeId
GROUP BY vt.Name
ORDER BY VoteCount DESC;
