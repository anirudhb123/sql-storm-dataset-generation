-- Performance Benchmarking SQL Query
-- This query retrieves average statistics of posts, users, and comments for performance analysis.

WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        AVG(u.Views) AS AvgViews,
        AVG(u.UpVotes) AS AvgUpVotes,
        AVG(u.DownVotes) AS AvgDownVotes
    FROM 
        Users u
    GROUP BY 
        u.Id
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(*) AS TotalComments,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.AvgScore,
    ps.AvgViewCount,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    us.AvgReputation,
    us.AvgViews,
    us.AvgUpVotes,
    us.AvgDownVotes,
    cs.TotalComments,
    cs.AvgCommentScore
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
JOIN 
    UserStats us ON us.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId = ps.PostTypeId)
LEFT JOIN 
    CommentStats cs ON cs.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = ps.PostTypeId)
ORDER BY 
    pt.Name;
