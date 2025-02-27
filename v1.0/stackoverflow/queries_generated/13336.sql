-- Performance Benchmarking Query

-- This query analyzes the average number of comments per post and the average vote score of posts over time.
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS VoteScore, -- Upvotes - Downvotes
        DATE_TRUNC('month', p.CreationDate) AS MonthYear
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, MonthYear
),
AverageStats AS (
    SELECT 
        MonthYear,
        AVG(CommentCount) AS AvgComments,
        AVG(VoteScore) AS AvgVoteScore
    FROM 
        PostStats
    GROUP BY 
        MonthYear
)
SELECT 
    MonthYear,
    AvgComments,
    AvgVoteScore
FROM 
    AverageStats
ORDER BY 
    MonthYear DESC;
