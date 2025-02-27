WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers, 
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM Users u 
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM Posts p 
    LEFT JOIN Comments c ON p.Id = c.PostId 
    LEFT JOIN Votes v ON p.Id = v.PostId 
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
PostStats AS (
    SELECT 
        pi.PostId, 
        pi.Title, 
        pi.CreationDate, 
        pi.CommentCount, 
        pi.VoteCount, 
        ps.TotalQuestions,
        ps.TotalAnswers,
        RANK() OVER (ORDER BY pi.VoteCount DESC) AS PopularityRank
    FROM PostInteractions pi
    JOIN TopUsers ps ON ps.TotalQuestions > 10 AND ps.TotalAnswers > 10
)
SELECT 
    tu.ReputationRank, 
    tu.DisplayName, 
    ps.PostId, 
    ps.Title, 
    ps.CreationDate, 
    ps.CommentCount, 
    ps.VoteCount, 
    ps.PopularityRank
FROM TopUsers tu 
JOIN PostStats ps ON tu.UserId = ps.PostId
WHERE tu.TotalPosts > 5
ORDER BY tu.ReputationRank, ps.PopularityRank;
