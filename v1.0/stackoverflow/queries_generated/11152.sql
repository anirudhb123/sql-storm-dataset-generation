-- Performance benchmarking query to analyze post statistics 
-- and user engagement on a Stack Overflow-like schema

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter posts created in the last year
),

Benchmark AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViews,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswers,
        AVG(CommentCount) AS AvgComments,
        AVG(VoteCount) AS AvgVotes,
        AVG(OwnerReputation) AS AvgOwnerReputation
    FROM 
        PostStats
)

SELECT 
    TotalPosts,
    AvgViews,
    AvgScore,
    AvgAnswers,
    AvgComments,
    AvgVotes,
    AvgOwnerReputation
FROM 
    Benchmark;
