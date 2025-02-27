-- Performance Benchmarking Query

-- This query retrieves various aggregated metrics for posts including question counts, answer counts,
-- vote counts, and average reputation of users who posted, grouped by PostTypeId.

WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation AS UserReputation
    FROM Users U
),
PostMetrics AS (
    SELECT 
        P.PostTypeId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,         -- UpMod
        SUM(V.VoteTypeId = 3) AS TotalDownVotes,       -- DownMod
        AVG(UM.UserReputation) AS AvgUserReputation    -- Average Reputation of Users who posted
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN UserMetrics UM ON P.OwnerUserId = UM.UserId
    WHERE P.CreationDate >= '2020-01-01' -- Filter to assess posts starting from the year 2020
    GROUP BY P.PostTypeId
)

SELECT 
    PT.Name AS PostTypeName,
    PM.QuestionCount,
    PM.AnswerCount,
    PM.TotalUpVotes,
    PM.TotalDownVotes,
    PM.AvgUserReputation
FROM PostMetrics PM
JOIN PostTypes PT ON PM.PostTypeId = PT.Id
ORDER BY PM.PostTypeId;
