
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
        Posts AS p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) AS c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) AS v ON p.Id = v.PostId
    LEFT JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
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
