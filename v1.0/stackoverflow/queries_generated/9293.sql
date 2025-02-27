WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),

PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        COUNT(c.Id) AS TotalComments,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),

UserPostDetails AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.Score,
        ps.TotalComments,
        ps.LastVoteDate
    FROM RankedUsers ru
    JOIN Posts ps ON ru.UserId = ps.OwnerUserId
),

TopPostStats AS (
    SELECT 
        upd.DisplayName,
        COUNT(upd.PostId) AS TotalPosts,
        SUM(upd.ViewCount) AS TotalViews,
        AVG(upd.Score) AS AverageScore,
        AVG(upd.AnswerCount) AS AverageAnswers,
        AVG(upd.CommentCount) AS AverageComments,
        MAX(ps.LastVoteDate) AS LastActivity
    FROM UserPostDetails upd
    JOIN PostStatistics ps ON upd.PostId = ps.PostId
    GROUP BY upd.DisplayName
    ORDER BY TotalPosts DESC
    LIMIT 10
)

SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.TotalViews,
    t.AverageScore,
    t.AverageAnswers,
    t.AverageComments,
    t.LastActivity,
    ru.ReputationRank
FROM TopPostStats t
JOIN RankedUsers ru ON t.DisplayName = ru.DisplayName;
