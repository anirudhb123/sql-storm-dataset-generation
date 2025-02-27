
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name ORDER BY B.Name SEPARATOR ', ') AS Badges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
UserStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.TotalViews,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.AverageScore,
        BS.BadgeCount,
        BS.Badges
    FROM 
        UserActivity UA
    JOIN 
        BadgeStats BS ON UA.UserId = BS.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.TotalViews,
    CASE 
        WHEN US.QuestionCount > US.AnswerCount THEN 'More Questions'
        ELSE 'More Answers or Equal'
    END AS QuestionVsAnswer,
    US.BadgeCount,
    COALESCE(US.Badges, 'No Badges') AS BadgeList,
    @rank1 := @rank1 + 1 AS ReputationRank,
    @rank2 := IF(@prevReputation = US.Reputation, @rank2, @rank2 + 1) AS ViewRank,
    @prevReputation := US.Reputation AS tmp,
    @row_number := IF(@category = CASE WHEN US.Reputation > 1000 THEN 'HighRep' ELSE 'LowRep' END, @row_number + 1, 1) AS UserCategory,
    @category := CASE WHEN US.Reputation > 1000 THEN 'HighRep' ELSE 'LowRep' END
FROM 
    UserStats US, 
    (SELECT @rank1 := 0, @rank2 := 0, @prevReputation := NULL, @row_number := 0, @category := '') AS vars
WHERE 
    US.Reputation >= (SELECT AVG(Reputation) FROM Users) 
    AND US.BadgeCount > 0 
ORDER BY 
    US.PostCount DESC,
    US.Reputation DESC;
