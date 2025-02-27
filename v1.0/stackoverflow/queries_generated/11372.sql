-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikiCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditHistoryCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TagWikiCount,
    U.AverageScore,
    PH.EditHistoryCount,
    PH.CloseReopenCount
FROM 
    UserStats U
LEFT JOIN 
    PostHistoryCounts PH ON U.PostCount > 0 -- Joins on users with created posts
ORDER BY 
    U.Reputation DESC, 
    U.PostCount DESC;
