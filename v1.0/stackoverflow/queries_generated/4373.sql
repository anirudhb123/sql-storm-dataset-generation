WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.ViewCount) AS AverageViewCount,
        COALESCE(SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswersCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
PostHistoryCounts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 24)  -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY 
        PH.UserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    PS.TotalPosts,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.AverageViewCount,
    PHC.EditCount,
    COALESCE(UR2.ReputationRank, 'N/A') AS ReputationRank
FROM 
    UserReputation UR
LEFT JOIN 
    PostStatistics PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN 
    PostHistoryCounts PHC ON UR.UserId = PHC.UserId
LEFT JOIN 
    UserReputation UR2 ON UR.Reputation > UR2.Reputation
WHERE 
    (PS.TotalPosts > 5 OR PS.TotalQuestions > 3)
    AND UR.Reputation IS NOT NULL
ORDER BY 
    UR.Reputation DESC, 
    PS.TotalPosts DESC
LIMIT 100;
