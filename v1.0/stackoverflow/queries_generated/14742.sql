-- Performance benchmarking query to retrieve user activity and post statistics
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalViews,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes,
    AVG(p.Score) AS AveragePostScore,
    MAX(p.CreationDate) AS LastPostDate
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  -- Answers
LEFT JOIN Comments c ON u.Id = c.UserId
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY u.Id, u.DisplayName, u.Reputation
ORDER BY TotalPosts DESC, Reputation DESC;
