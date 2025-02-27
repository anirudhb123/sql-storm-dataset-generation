-- Performance benchmarking query for Stack Overflow schema
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(A.Id), 0) AS AnswerCount,
        COALESCE(SUM(VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1  -- Questions and their answers
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'  -- Example filter for posts created in 2023
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
AverageMetrics AS (
    SELECT 
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        PostMetrics
)
SELECT 
    PM.*,
    AM.AvgViewCount,
    AM.AvgScore,
    AM.AvgAnswerCount,
    AM.AvgCommentCount,
    AM.TotalUpVotes,
    AM.TotalDownVotes
FROM 
    PostMetrics PM, 
    AverageMetrics AM
ORDER BY 
    PM.ViewCount DESC;  -- Order by view count for performance analysis
