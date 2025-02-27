
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
RankedUserActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalQuestions,
        ua.TotalAnswers,
        @rank := @rank + 1 AS Rank
    FROM UserActivity ua, (SELECT @rank := 0) r
    WHERE ua.TotalQuestions > 0
    ORDER BY ua.TotalQuestions DESC, ua.TotalAnswers DESC
),
RecentVotes AS (
    SELECT 
        v.UserId,
        COUNT(*) AS RecentVoteCount
    FROM Votes v
    WHERE v.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY v.UserId
)

SELECT 
    rua.DisplayName,
    rua.TotalQuestions,
    rua.TotalAnswers,
    COALESCE(rv.RecentVoteCount, 0) AS RecentVoteCount,
    CASE 
        WHEN rv.RecentVoteCount IS NULL THEN 'No recent votes'
        WHEN rv.RecentVoteCount > 10 THEN 'Active voter'
        ELSE 'Occasional voter'
    END AS VotingStatus
FROM RankedUserActivity rua
LEFT JOIN RecentVotes rv ON rua.UserId = rv.UserId
WHERE rua.Rank <= 100
ORDER BY rua.Rank;
