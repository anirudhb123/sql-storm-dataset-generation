-- Performance benchmarking query to analyze post activity and user engagement on Stack Overflow

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT v.UserId) AS TotalVotes,
        MIN(v.CreationDate) AS FirstVoteDate,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Consider posts created within the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalPostViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.Score,
    ps.TotalComments,
    ps.TotalVotes,
    ups.UserId,
    ups.TotalPosts,
    ups.TotalPostViews,
    ups.TotalAnswers,
    ups.TotalComments AS UserTotalComments,
    ps.FirstVoteDate,
    ps.LastVoteDate
FROM 
    PostStats ps
LEFT JOIN 
    UserPostStats ups ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ups.UserId)
ORDER BY 
    ps.ViewCount DESC -- Sorting by post views for benchmarking purposes
LIMIT 100; -- Limit results to top 100 posts by view count
