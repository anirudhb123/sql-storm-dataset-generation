
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        AVG(p.Score) AS AvgPostScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        p.CreationDate,
        @row_number := @row_number + 1 AS PostRank,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0) AS r
    WHERE p.PostTypeId = 1 
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.AvgPostScore,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.PostRank
FROM UserStats us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY us.TotalUpVotes DESC, ps.ViewCount DESC;
