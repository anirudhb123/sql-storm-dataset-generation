WITH RecursiveTopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 0
    UNION ALL
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    JOIN RecursiveTopUsers rtu ON u.Reputation < rtu.Reputation
    WHERE rtu.UserRank < 100
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts p
    GROUP BY p.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        h.PostId,
        MAX(h.CreationDate) AS LastEdited,
        COUNT(*) AS TotalEdits
    FROM PostHistory h
    GROUP BY h.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        COALESCE(phs.TotalEdits, 0) AS TotalEdits,
        COALESCE(phs.LastEdited, NULL) AS LastEdited
    FROM Users u
    LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
    LEFT JOIN PostHistorySummary phs ON phs.PostId IN (
        SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id
    )
),
FilteredUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalEdits,
        ua.LastEdited,
        RANK() OVER (ORDER BY ua.TotalPosts DESC, ua.TotalEdits DESC) AS ActivityRank
    FROM UserActivity ua
    WHERE ua.TotalPosts IS NOT NULL
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    fu.TotalPosts,
    fu.TotalQuestions,
    fu.TotalAnswers,
    fu.TotalEdits,
    fu.LastEdited
FROM RecursiveTopUsers tu
FULL OUTER JOIN FilteredUsers fu ON tu.Id = fu.UserId
WHERE (tu.UserRank <= 10 OR fu.ActivityRank <= 10)
ORDER BY 
    COALESCE(tu.Reputation, 0) DESC,
    COALESCE(fu.TotalPosts, 0) DESC;
