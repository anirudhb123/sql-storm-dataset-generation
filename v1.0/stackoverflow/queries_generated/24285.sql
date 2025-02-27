WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) OVER (PARTITION BY NULL) AS AvgReputation,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation IS NOT NULL AND u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
), QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes,
        COALESCE(SUM(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        STRING_AGG(DISTINCT tg.TagName, ', ') AS Tags,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN CONCAT('Closed: ', ph.Comment) END, '; ') AS CloseReasons
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN Tags tg ON tg.WikiPostId = p.Id
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate
), UserPostAnalysis AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.AvgReputation,
        qs.QuestionId,
        qs.Title,
        qs.TotalUpvotes,
        qs.TotalDownvotes,
        qs.CommentCount,
        qs.CloseCount,
        qs.Tags,
        qs.CloseReasons,
        DENSE_RANK() OVER (ORDER BY us.AvgReputation DESC) AS ReputationRank
    FROM UserStats us
    JOIN QuestionStats qs ON us.TotalQuestions > 0
)
SELECT 
    upa.DisplayName,
    upa.TotalPosts,
    upa.TotalQuestions,
    upa.TotalAnswers,
    upa.AvgReputation,
    upa.ReputationRank,
    upa.Title AS QuestionTitle,
    upa.TotalUpvotes,
    upa.TotalDownvotes,
    upa.CommentCount,
    upa.CloseCount,
    upa.Tags,
    CASE 
        WHEN upa.CloseCount > 0 THEN 'This question has been closed'
        ELSE 'This question is open'
    END AS QuestionStatus,
    CASE 
        WHEN upa.ReputationRank <= 5 THEN 'Top Contributor'
        WHEN upa.ReputationRank BETWEEN 6 AND 20 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM UserPostAnalysis upa
WHERE EXISTS (
    SELECT 1 
    FROM Posts p 
    WHERE p.OwnerUserId = upa.UserId AND p.PostTypeId = 1 
    HAVING COUNT(p.Id) > 0
)
ORDER BY upa.AvgReputation DESC, upa.TotalPosts DESC
FETCH FIRST 100 ROWS ONLY;
