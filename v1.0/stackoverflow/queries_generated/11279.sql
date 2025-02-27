-- Performance Benchmarking Query
-- This query retrieves statistics on posts and their associated users, votes, and comments

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.Reputation, u.DisplayName
),
AvgScore AS (
    SELECT 
        AVG(Score) AS AvgPostScore,
        COUNT(*) AS TotalPosts
    FROM 
        PostStats
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerReputation,
    ps.OwnerDisplayName,
    ps.VoteCount,
    a.AvgPostScore,
    a.TotalPosts
FROM 
    PostStats ps
CROSS JOIN 
    AvgScore a
ORDER BY 
    ps.Score DESC
LIMIT 10;
