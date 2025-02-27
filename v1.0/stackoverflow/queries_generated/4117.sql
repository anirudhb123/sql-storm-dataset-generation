WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.ViewCount) AS AvgViewCount,
        DENSE_RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentPostEdits AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        JSON_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY ph.PostId
),
HighScorePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.Score > 0
),
TopUsers AS (
    SELECT 
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        r.PostId,
        r.LastEditDate,
        r.EditCount,
        r.Editors
    FROM UserPostStats ups
    JOIN RecentPostEdits r ON ups.UserId = r.PostId
    WHERE ups.TotalPosts > 10
    ORDER BY ups.TotalPosts DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    hp.Title,
    hp.Score,
    hp.ScoreRank,
    r.LastEditDate,
    r.EditCount,
    r.Editors
FROM TopUsers tu
JOIN HighScorePosts hp ON tu.UserId = hp.PostId
LEFT JOIN RecentPostEdits r ON hp.PostId = r.PostId
WHERE hp.ScoreRank <= 10
ORDER BY tu.TotalPosts DESC, hp.Score DESC;
