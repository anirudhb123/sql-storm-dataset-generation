SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(COALESCE(p.Score, 0)) AS AveragePostScore,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypeNames,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    SUM(CASE WHEN bh.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
    SUM(CASE WHEN bh.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopenedPosts
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN PostHistory bh ON p.Id = bh.PostId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName
ORDER BY TotalPosts DESC, AveragePostScore DESC
LIMIT 50;
