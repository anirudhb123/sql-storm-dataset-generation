WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS RankTotalPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT UserId, DisplayName, TotalPosts, TotalQuestions, TotalAnswers, TotalBounty
    FROM UserStatistics
    WHERE RankTotalPosts <= 10
),
PostWithHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        PHT.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentHistory
    FROM Posts p
    INNER JOIN PostHistory ph ON p.Id = ph.PostId
    INNER JOIN PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE ph.CreationDate > NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalBounty,
    COALESCE(ph.Title, 'No Posts') AS RecentlyEditedPost,
    ph.HistoryDate,
    ph.HistoryType,
    ph.Comment
FROM Users u
LEFT JOIN TopActiveUsers ua ON u.Id = ua.UserId
LEFT JOIN PostWithHistory ph ON u.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = ph.PostId LIMIT 1)
WHERE u.Reputation > (
    SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL
) AND (ua.TotalPosts IS NOT NULL OR ph.PostId IS NOT NULL)
ORDER BY u.Reputation DESC, ua.TotalPosts DESC
LIMIT 50;

This query performs the following tasks:
1. **CTE (UserStatistics)**: It calculates statistics for users, including total posts, total questions and answers, and total bounties received, ranking them by total posts.
2. **CTE (TopActiveUsers)**: It selects the top ten users based on total posts.
3. **CTE (PostWithHistory)**: It gathers posts with their associated history changes that occurred within the last year, including details like the type of history action and any comments provided.
4. **Final Select**: It retrieves user details along with their post statistics if they exceed the average reputation, with outer logic ensuring that if a user has no posts or recent history, their data is still displayed, but with appropriate defaults.
5. **Ordering & Limiting**: The final results are ordered and limited to showcase the most relevant top users based on reputation and posts, incorporating NULL logic in a meaningful way.

This SQL showcases several constructs, including CTEs, window functions, subqueries, and outer joins, forming a complex yet powerful query suitable for performance benchmarking.
