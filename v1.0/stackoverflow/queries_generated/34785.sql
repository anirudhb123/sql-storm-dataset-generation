WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id,
        u.Reputation,
        1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        urc.Level + 1
    FROM Users u
    JOIN UserReputationCTE urc ON urc.Reputation < u.Reputation
    WHERE u.Reputation < 10000
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts p
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY p.OwnerUserId
),
VoteSummary AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    WHERE v.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY v.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    urc.Level AS ReputationLevel,
    ps.PostCount,
    ps.AvgScore,
    ps.QuestionCount,
    ps.AnswerCount,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN ps.AvgScore IS NOT NULL THEN 
            CASE 
                WHEN ps.AvgScore >= 10 THEN 'High'
                WHEN ps.AvgScore BETWEEN 5 AND 10 THEN 'Medium'
                ELSE 'Low'
            END
        ELSE 'No Posts'
    END AS ScoreCategory
FROM Users u
LEFT JOIN UserReputationCTE urc ON u.Id = urc.Id
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN VoteSummary vs ON u.Id = vs.UserId
WHERE u.Reputation > 0
ORDER BY u.Reputation DESC;
