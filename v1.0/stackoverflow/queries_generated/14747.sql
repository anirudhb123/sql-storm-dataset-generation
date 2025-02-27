-- Performance Benchmarking SQL Query
-- This query retrieves statistics on posts, users, and votes to assess performance metrics.

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.AnswerCount) AS AverageAnswerCount,
        AVG(p.CommentCount) AS AverageCommentCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(u.Reputation) AS AverageReputation,
        MAX(u.LastAccessDate) AS MostRecentAccessDate
    FROM 
        Users u
),
VoteStats AS (
    SELECT 
        v.VoteTypeId,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.VoteTypeId
)

SELECT 
    p.PostTypeId,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AverageViewCount,
    ps.AverageAnswerCount,
    ps.AverageCommentCount,
    us.TotalUsers,
    us.AverageReputation,
    us.MostRecentAccessDate,
    vs.VoteTypeId,
    vs.TotalVotes
FROM 
    PostStats ps
JOIN 
    UserStats us ON 1=1  -- Cross join to combine user stats with post stats
JOIN 
    VoteStats vs ON 1=1  -- Cross join to combine vote stats with post stats
ORDER BY 
    p.PostTypeId, vs.VoteTypeId;
