WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        PS.PostCount,
        PS.AnswerCount,
        PS.QuestionCount,
        PS.TotalScore,
        CASE 
            WHEN PS.QuestionCount > 0 THEN ROUND(PS.TotalScore::numeric / PS.QuestionCount, 2)
            ELSE 0
        END AS AvgScorePerQuestion
    FROM 
        UserReputation U
    LEFT JOIN 
        PostStatistics PS ON U.UserId = PS.OwnerUserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    *,
    CASE 
        WHEN AvgScorePerQuestion > 5 THEN 'High Scorer'
        WHEN AvgScorePerQuestion BETWEEN 1 AND 5 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoringCategory,
    (SELECT STRING_AGG(CONCAT_WS(': ', T.TagName, T.Count), ', ') 
     FROM Tags T 
     WHERE T.Id IN (SELECT unnest(STRING_TO_ARRAY(P.Tags, '><')::int[]))
     ) AS TagSummary
FROM 
    CombinedStats
ORDER BY 
    Reputation DESC, 
    PostCount DESC
LIMIT 10;
