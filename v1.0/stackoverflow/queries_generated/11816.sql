-- Performance Benchmarking SQL Query

WITH PostsSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT a.Id) AS AnswersCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    u.UserId,
    u.DisplayName AS UserName,
    u.PostsCount,
    u.CommentsCount,
    u.AnswersCount,
    u.UpVotes,
    u.DownVotes
FROM PostsSummary p
JOIN UserActivity u ON p.PostId = u.UserId
ORDER BY p.CreationDate DESC
LIMIT 100;
