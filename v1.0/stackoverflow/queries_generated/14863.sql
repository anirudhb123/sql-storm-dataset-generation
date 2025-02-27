-- Performance Benchmarking SQL Query

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TotalTagWikis,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.Reputation, u.UpVotes, u.DownVotes
),

PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(AVG(v.VoteTypeId), 0) AS AvgVoteType,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
)

SELECT 
    u.UserId,
    u.Reputation,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalTagWikis,
    u.TotalComments,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    p.AvgVoteType,
    p.TotalUpvotes,
    p.TotalDownvotes
FROM 
    UserStats u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
ORDER BY 
    u.Reputation DESC, p.Score DESC
LIMIT 100;
