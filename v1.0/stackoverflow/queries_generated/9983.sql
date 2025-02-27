WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT OwnerUserId, 
           COUNT(*) AS TotalPosts,
           SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(ViewCount) AS TotalViews,
           AVG(ViewCount) AS AvgViewsPerPost
    FROM Posts
    GROUP BY OwnerUserId
),
CommentStats AS (
    SELECT PostId, COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY PostId
),
VotesStats AS (
    SELECT PostId, 
           COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
           COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownVotes
    FROM Votes
    GROUP BY PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AvgViewsPerPost, 0) AS AvgViewsPerPost,
    COALESCE(cs.TotalComments, 0) AS TotalComments,
    COALESCE(vs.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.TotalDownVotes, 0) AS TotalDownVotes
FROM Users u
LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN CommentStats cs ON cs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN VotesStats vs ON vs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE u.Reputation > 100
ORDER BY u.Reputation DESC;
