WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS PopularityRank
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        CREATETIME AS ClosedTime
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)
)
SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.TotalUpvotes,
    ups.TotalDownvotes,
    pq.Title AS PopularQuestionTitle,
    pq.TotalViews AS QuestionViews,
    cp.CreationDate AS ClosureDate
FROM UserPostStats ups
LEFT JOIN PopularQuestions pq ON pq.PopularityRank = 1
LEFT JOIN ClosedPosts cp ON cp.UserId = ups.UserId
WHERE ups.TotalPosts > 0
ORDER BY ups.ViewRank, ups.TotalPosts DESC;
