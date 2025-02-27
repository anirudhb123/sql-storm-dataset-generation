
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COALESCE(ph.VoteCount, 0) AS VoteCount,
        COALESCE(com.CommentCount, 0) AS CommentCount,
        COALESCE(ans.AnswerCount, 0) AS AnswerCount,
        p.Score,
        @rank := IF(@prev_post_type_id = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId,
        p.OwnerUserId
    FROM Posts p
    JOIN (SELECT @rank := 0, @prev_post_type_id := NULL) r 
    WHERE p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) com ON p.Id = com.PostId
    LEFT JOIN (
        SELECT ParentId AS PostId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) ans ON p.Id = ans.PostId
)
SELECT 
    us.DisplayName,
    us.Upvotes,
    us.Downvotes,
    ps.Title,
    ps.VoteCount,
    ps.CommentCount,
    ps.AnswerCount
FROM UserVoteStats us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
WHERE ps.Rank <= 10
ORDER BY ps.Score DESC, ps.Title;
