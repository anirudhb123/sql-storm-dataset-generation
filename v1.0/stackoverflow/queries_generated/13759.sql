-- Performance benchmarking query to analyze user engagement and post interactions
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(c.Score) AS TotalCommentScore,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.TotalCommentScore,
    ua.UpVotes,
    ua.DownVotes,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.PostType
FROM UserActivity ua
JOIN PostSummary ps ON ua.UserId = ps.OwnerUserId
ORDER BY ua.TotalPosts DESC, ps.ViewCount DESC;
