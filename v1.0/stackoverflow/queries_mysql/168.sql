
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalViews
    FROM UserReputation ur
    JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    WHERE ur.Reputation > 1000
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActivity
    FROM Posts p
    GROUP BY p.OwnerUserId
),
FinalMetrics AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.Reputation,
        au.TotalPosts,
        au.QuestionCount,
        au.AnswerCount,
        au.TotalViews,
        rpa.LastActivity,
        CASE 
            WHEN rpa.LastActivity IS NULL THEN 'Inactive' 
            WHEN rpa.LastActivity < (NOW() - INTERVAL 1 YEAR) THEN 'Dormant' 
            ELSE 'Active' 
        END AS ActivityStatus
    FROM ActiveUsers au
    LEFT JOIN RecentPostActivity rpa ON au.UserId = rpa.OwnerUserId
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.TotalPosts,
    f.QuestionCount,
    f.AnswerCount,
    f.TotalViews,
    f.ActivityStatus,
    COALESCE(NULLIF(f.QuestionCount, 0), 1) AS SafeQuestionCount, 
    (CAST(f.TotalViews AS DECIMAL(10, 2)) / NULLIF(f.QuestionCount, 0)) AS AverageViewsPerQuestion 
FROM FinalMetrics f 
ORDER BY f.Reputation DESC, f.TotalPosts DESC
LIMIT 100;
