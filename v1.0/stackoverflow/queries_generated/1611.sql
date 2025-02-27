WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
), PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
), UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS Gold,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS Silver,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS Bronze
    FROM Badges B
    GROUP BY B.UserId
), UserDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS TotalQuestions,
        COALESCE(PS.Answers, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        UR.ReputationRank
    FROM Users U
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN PostSummary PS ON U.Id = PS.OwnerUserId
    LEFT JOIN UserReputation UR ON U.Id = UR.UserId
), RankedUsers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS OverallRank
    FROM UserDetails
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.ReputationRank,
    U.BadgeCount,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalViews,
    R.OverallRank
FROM UserDetails U
JOIN RankedUsers R ON U.UserId = R.UserId
WHERE U.BadgeCount > 0 AND U.TotalPosts > 10
ORDER BY R.OverallRank, U.Reputation DESC;
