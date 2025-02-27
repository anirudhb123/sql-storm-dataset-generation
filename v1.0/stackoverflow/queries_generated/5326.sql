WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AvgReputation,
        MAX(p.CreationDate) AS LastActivity
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        AvgReputation,
        LastActivity,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS Rank
    FROM UserStats
),
ActiveUserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ps.UserDisplayName,
        ps.Rank
    FROM Posts p
    JOIN TopUsers ps ON p.OwnerUserId = ps.UserId
    WHERE ps.Rank <= 10
)
SELECT 
    u.DisplayName AS UserName,
    COUNT(ap.PostId) AS ActivePostsCount,
    AVG(DATEDIFF(CURDATE(), ap.CreationDate)) AS AvgDaysSincePost
FROM TopUsers u
LEFT JOIN ActiveUserPosts ap ON u.UserId = ap.UserId
GROUP BY u.UserId, u.DisplayName
ORDER BY ActivePostsCount DESC, AvgDaysSincePost ASC;
