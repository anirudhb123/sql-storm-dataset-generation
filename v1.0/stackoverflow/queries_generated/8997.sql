WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN P.IsClosed = 1 THEN 1 END) AS ClosedCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.CreationDate - U.CreationDate) AS AvgPostAge
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.OwnerUserId
),
ReputationRanks AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.ClosedCount,
        PS.TotalScore,
        PS.TotalViews,
        PS.AvgPostAge,
        DENSE_RANK() OVER (ORDER BY UR.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation UR
    JOIN 
        PostSummary PS ON UR.UserId = PS.OwnerUserId
)
SELECT 
    RR.ReputationRank,
    RR.DisplayName,
    RR.Reputation,
    RR.QuestionCount,
    RR.AnswerCount,
    RR.ClosedCount,
    RR.TotalScore,
    RR.TotalViews,
    RR.AvgPostAge,
    B.Name AS BadgeName,
    B.Class
FROM 
    ReputationRanks RR
LEFT JOIN 
    Badges B ON RR.UserId = B.UserId
ORDER BY 
    RR.ReputationRank, B.Class DESC, RR.DisplayName
LIMIT 100;
