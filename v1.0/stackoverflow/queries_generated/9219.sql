WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScores
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HighReputationUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, BadgeCount, QuestionCount, AnswerCount, TotalViews, TotalScores,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
    WHERE 
        Reputation > 5000
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, BadgeCount, QuestionCount, AnswerCount, TotalViews, TotalScores
    FROM 
        HighReputationUsers
    WHERE 
        ReputationRank <= 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalViews,
    U.TotalScores,
    COALESCE(AVG(CAST(PH.CreationDate AS DATE)), 'Never') AS AveragePostHistoryDate
FROM 
    TopUsers U
LEFT JOIN 
    PostHistory PH ON U.UserId = PH.UserId
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation, U.BadgeCount, U.QuestionCount, U.AnswerCount, U.TotalViews, U.TotalScores
ORDER BY 
    U.Reputation DESC;
