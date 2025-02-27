
WITH 
    UserStats AS (
        SELECT 
            u.Id AS UserId,
            u.DisplayName,
            u.Reputation,
            u.Views,
            u.UpVotes,
            u.DownVotes,
            ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.LastAccessDate DESC) AS AccessRank
        FROM Users u
        WHERE u.Reputation > 1000
    ),
    PostStats AS (
        SELECT 
            p.OwnerUserId,
            COUNT(*) AS PostCount,
            SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
            COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
            COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
            AVG(p.Score) AS AvgScore
        FROM Posts p
        WHERE p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR
        GROUP BY p.OwnerUserId
    ),
    CombinedStats AS (
        SELECT 
            us.UserId,
            us.DisplayName,
            us.Reputation,
            us.Views,
            us.UpVotes,
            us.DownVotes,
            ps.PostCount,
            ps.TotalViews,
            ps.QuestionCount,
            ps.AnswerCount,
            ps.AvgScore
        FROM UserStats us
        LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
    ),
    FilteredUsers AS (
        SELECT 
            *, 
            CASE 
                WHEN PostCount IS NULL THEN 'No Posts' 
                ELSE 'Active' 
            END AS UserStatus,
            CASE 
                WHEN AvgScore IS NULL THEN 'No Score' 
                ELSE 'Has Score' 
            END AS ScoreStatus
        FROM CombinedStats
    )
SELECT 
    fu.DisplayName,
    fu.Reputation,
    fu.Views,
    fu.UpVotes,
    fu.DownVotes,
    fu.PostCount,
    fu.TotalViews,
    fu.QuestionCount,
    fu.AnswerCount,
    fu.AvgScore,
    fu.UserStatus,
    fu.ScoreStatus,
    GROUP_CONCAT(DISTINCT pt.Name) AS PostTypes
FROM FilteredUsers fu
LEFT JOIN Posts p ON fu.UserId = p.OwnerUserId
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE fu.Reputation >= 5000
GROUP BY fu.UserId, fu.DisplayName, fu.Reputation, fu.Views, fu.UpVotes, 
         fu.DownVotes, fu.PostCount, fu.TotalViews, fu.QuestionCount, 
         fu.AnswerCount, fu.AvgScore, fu.UserStatus, fu.ScoreStatus
HAVING COUNT(p.Id) >= 5
ORDER BY fu.Reputation DESC, fu.PostCount DESC
LIMIT 100;
