-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'  -- Adjust based on the time frame of interest
),
AggregatedStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViews,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswers,
        AVG(CommentCount) AS AvgComments,
        AVG(OwnerReputation) AS AvgOwnerReputation
    FROM 
        PostStatistics
)
SELECT 
    *
FROM 
    AggregatedStats;
