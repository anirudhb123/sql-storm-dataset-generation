-- Benchmark query to analyze the average score of posts, total comments per post,
-- and user reputation with a focus on recent activity.

WITH PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Score AS PostScore,
        COUNT(c.Id) AS CommentCount,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'  -- Consider posts from the last 30 days
    GROUP BY 
        p.Id, u.Reputation
),
AverageStats AS (
    SELECT 
        AVG(PostScore) AS AvgPostScore,
        SUM(CommentCount) AS TotalComments,
        AVG(UserReputation) AS AvgUserReputation
    FROM 
        PostScore
)

SELECT 
    * 
FROM 
    AverageStats;
