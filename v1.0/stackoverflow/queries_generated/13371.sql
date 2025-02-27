-- Performance Benchmarking Query

-- This query aims to assess the performance of various joins and aggregations
-- across multiple tables, including Posts, Users, Votes, and Comments.

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,  -- UpMod votes
        SUM(v.VoteTypeId = 3) AS TotalDownVotes  -- DownMod votes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    UserPostStats ups
LEFT JOIN 
    PostComments pc ON ups.TotalPosts = pc.PostId
ORDER BY 
    ups.DisplayName;
