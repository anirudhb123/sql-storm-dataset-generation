-- Performance benchmarking SQL query for analyzing posts and their engagement
WITH PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 -- Filtering for questions only
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    Upvotes,
    Downvotes,
    (ViewCount + Score + AnswerCount + CommentCount + Upvotes - Downvotes) AS EngagementScore
FROM 
    PostEngagement
ORDER BY 
    EngagementScore DESC
LIMIT 10; -- Limiting to top 10 engaging posts
