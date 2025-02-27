WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Reputation > 50 THEN 1 ELSE 0 END) AS HighReputationPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE v.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY v.UserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.HighReputationPosts,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        COALESCE(rv.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(rv.DownVotesCount, 0) AS DownVotesCount
    FROM UserStats us
    LEFT JOIN RecentVotes rv ON us.UserId = rv.UserId
    ORDER BY us.Reputation DESC
    LIMIT 10
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.HighReputationPosts,
    t.RecentVoteCount,
    t.UpVotesCount,
    t.DownVotesCount
FROM TopUsers t
WHERE EXISTS (
    SELECT 1
    FROM Badges b
    WHERE b.UserId = t.UserId
    AND b.Class = 1 /* Gold badges */
)
ORDER BY t.Reputation DESC;
