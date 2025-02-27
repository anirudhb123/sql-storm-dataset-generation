
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
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'  
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
    GROUP BY 
        PostId, CreationDate, ViewCount, Score, AnswerCount, CommentCount, OwnerReputation
)
SELECT 
    *
FROM 
    AggregatedStats;
