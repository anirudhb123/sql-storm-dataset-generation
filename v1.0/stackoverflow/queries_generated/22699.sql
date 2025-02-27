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
            SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
            COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
            COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
            AVG(p.Score) AS AvgScore
        FROM Posts p
        WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
    STRING_AGG(DISTINCT pt.Name) AS PostTypes
FROM FilteredUsers fu
LEFT JOIN Posts p ON fu.UserId = p.OwnerUserId
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE fu.Reputation >= 5000
GROUP BY fu.DisplayName, fu.Reputation, fu.Views, fu.UpVotes, fu.DownVotes, 
         fu.PostCount, fu.TotalViews, fu.QuestionCount, 
         fu.AnswerCount, fu.AvgScore, fu.UserStatus, fu.ScoreStatus
HAVING COUNT(p.Id) >= 5
ORDER BY fu.Reputation DESC, fu.PostCount DESC
LIMIT 100;
This elaborate SQL query combines various constructs, including Common Table Expressions (CTEs) and window functions, to profile users based on their activities over the last year. The query produces an interesting profile of active users who meet certain reputation thresholds and examines their post-related metrics, including types of posts they've authored. It also includes conditional logic for additional categorization based on user activity and post scores. This allows for performance benchmarking against user engagement in a Stack Overflow-like environment.
